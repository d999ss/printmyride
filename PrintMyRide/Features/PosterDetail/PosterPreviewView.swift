import SwiftUI

struct PosterPreviewView: View {
    let poster: StorePoster
    @State private var page = 0
    @State private var showChrome = true
    @State private var showVariants = false
    @State private var selectedVariant: Variant?
    @StateObject private var authService = AuthService.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        Gallery(imageSources: poster.imageSources, page: $page, showChrome: $showChrome)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(poster.title)
                                .font(.title2.weight(.semibold))
                                .accessibilityAddTraits(.isHeader)

                            Text(formattedPrice(base: poster.priceCents, delta: selectedVariant?.priceDeltaCents ?? 0, currency: poster.currency))
                                .font(.title3)

                            VariantButton(selectedVariant: $selectedVariant) {
                                showVariants = true
                            }

                            DetailsSection(poster: poster)
                            
                            // Add bottom padding to ensure content isn't hidden behind buy bar
                            Spacer()
                                .frame(height: 120)
                        }
                        .padding(16)
                    }
                }

                // Sticky Buy Bar (always visible for store posters)
                VStack {
                    Spacer()
                    BuyBar(
                        price: formattedPrice(base: poster.priceCents, delta: selectedVariant?.priceDeltaCents ?? 0, currency: poster.currency),
                        primaryAction: addToCart,
                        applePayAction: applePay
                    )
                }
                .allowsHitTesting(showChrome)
                .opacity(showChrome ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: showChrome)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(showChrome ? .visible : .hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar) // Hide bottom navigation for focused poster experience
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { 
                    Button("Done") { dismiss() }
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) { 
                    ShareLink(item: URL(string: "https://printmyride.app/poster/\(poster.id)")!) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showVariants) {
                VariantPickerSheet(variants: poster.variants, selected: $selectedVariant)
                    .presentationDetents([.medium, .large])
            }
            .task { preloadImages(imageSources: poster.imageSources) }
            .preferredColorScheme(.light) // this screen designed for light mode
        }
    }

    private func addToCart() {
        // haptics
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        // implement cart add - for now just haptic feedback
        print("Added \(poster.title) to cart")
    }
    
    private func applePay() { 
        // hook into Apple Pay if configured
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        print("Apple Pay for \(poster.title)")
    }
    

    private func formattedPrice(base: Int, delta: Int, currency: String) -> String {
        let total = base + delta
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: Double(total) / 100.0)) ?? ""
    }
    
    private func preloadImages(imageSources: [ImageSource]) {
        // Simple image preloading for remote URLs only
        for source in imageSources {
            if case .url(let url) = source {
                URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
            }
        }
    }
}

// MARK: - Gallery with paging + zoom + chrome toggle

private struct Gallery: View {
    let imageSources: [ImageSource]
    @Binding var page: Int
    @Binding var showChrome: Bool

    var body: some View {
        TabView(selection: $page) {
            ForEach(imageSources.indices, id: \.self) { idx in
                ZoomableImage(imageSource: imageSources[idx])
                    .tag(idx)
                    .contentShape(Rectangle())
                    .onTapGesture { 
                        withAnimation(.easeInOut(duration: 0.25)) { 
                            showChrome.toggle() 
                        }
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .frame(height: UIScreen.main.bounds.width * 1.25) // poster aspect hint
    }
}

// MARK: - Zoomable image (UIScrollView bridge)

struct ZoomableImage: View {
    let imageSource: ImageSource
    
    var body: some View {
        GeometryReader { geo in
            ZoomScroll {
                Group {
                    switch imageSource {
                    case .url(let url):
                        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width)
                                    .accessibilityLabel("Poster artwork")
                            case .failure:
                                Color.secondary.opacity(0.1)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    case .local(let imageName):
                        if let path = Bundle.main.path(forResource: imageName, ofType: "jpg"),
                           let image = UIImage(contentsOfFile: path) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width)
                                .accessibilityLabel("Poster artwork")
                        } else {
                            Color.secondary.opacity(0.1)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary)
                                        Text("Image: \(imageName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                    }
                }
            }
        }
    }
}

struct ZoomScroll<Content: View>: UIViewRepresentable {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.minimumZoomScale = 1.0
        scroll.maximumZoomScale = 3.0
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.delegate = context.coordinator
        scroll.backgroundColor = .clear
        
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(host.view)
        
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            host.view.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            host.view.centerYAnchor.constraint(equalTo: scroll.centerYAnchor)
        ])
        
        return scroll
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.subviews.first
        }
    }
}

// MARK: - Sticky Buy Bar (liquid glass)

private struct BuyBar: View {
    let price: String
    let primaryAction: () -> Void
    let applePayAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(price)
                .font(.headline)
            
            Spacer()
            
            Button("Add to Cart", action: primaryAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            
            // Optional Apple Pay button
            Button(action: applePayAction) {
                HStack(spacing: 4) {
                    Image(systemName: "applelogo")
                    Text("Pay")
                }
            }
            .buttonStyle(.bordered)
            .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 34) // Extra bottom padding for safe area + tab bar
        .background {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
        }
        .overlay(Divider(), alignment: .top)
    }
}


// MARK: - Details + Specs

private struct DetailsSection: View {
    let poster: StorePoster
    @State private var detailsExpanded = true
    @State private var specsExpanded = true
    
    var body: some View {
        VStack(spacing: 8) {
            DisclosureGroup("Details", isExpanded: $detailsExpanded) {
                Text(poster.story)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .disclosureGroupStyle(.automatic)

            DisclosureGroup("Specifications", isExpanded: $specsExpanded) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(poster.specs, id: \.name) { spec in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spec.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(spec.value)
                                .font(.callout)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Variant picker

private struct VariantButton: View {
    @Binding var selectedVariant: Variant?
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                Text(selectedVariant?.name ?? "Select size / frame")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(.thinMaterial))
        }
        .buttonStyle(.plain)
    }
}

private struct VariantPickerSheet: View {
    let variants: [Variant]
    @Binding var selected: Variant?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(variants) { variant in
                Button {
                    selected = variant
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(variant.name)
                                .foregroundColor(.primary)
                            if variant.priceDeltaCents != 0 {
                                Text(priceChangeText(variant.priceDeltaCents))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if selected?.id == variant.id { 
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("Choose Variant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func priceChangeText(_ deltaCents: Int) -> String {
        if deltaCents > 0 {
            return "+$\(String(format: "%.2f", Double(deltaCents) / 100.0))"
        } else if deltaCents < 0 {
            return "-$\(String(format: "%.2f", Double(-deltaCents) / 100.0))"
        } else {
            return ""
        }
    }
}

// MARK: - Convenience extensions

private extension View {
    func safeAreaInsetStyle() -> some View {
        self
            .background(.clear)
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    PosterPreviewView(poster: StorePoster.sample)
}