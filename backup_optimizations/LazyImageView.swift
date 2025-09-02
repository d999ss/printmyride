// PrintMyRide/UI/Optimizations/LazyImageView.swift
import SwiftUI
import Combine

/// High-performance lazy image loading with caching and progressive loading
struct LazyImageView: View {
    let imageKey: String
    let placeholder: AnyView
    let aspectRatio: CGFloat?
    let contentMode: ContentMode
    let imageLoader: () async -> UIImage?
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadingTask: Task<Void, Never>?
    
    init<Placeholder: View>(
        imageKey: String,
        aspectRatio: CGFloat? = nil,
        contentMode: ContentMode = .fit,
        @ViewBuilder placeholder: () -> Placeholder,
        imageLoader: @escaping () async -> UIImage?
    ) {
        self.imageKey = imageKey
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
        self.placeholder = AnyView(placeholder())
        self.imageLoader = imageLoader
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: contentMode)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                placeholder
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                            .opacity(isLoading ? 1 : 0)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            cancelLoading()
        }
        .onChange(of: imageKey) { _, _ in
            cancelLoading()
            loadedImage = nil
            loadImage()
        }
        .animation(.easeInOut(duration: 0.3), value: loadedImage != nil)
    }
    
    private func loadImage() {
        guard loadedImage == nil && !isLoading else { return }
        
        loadingTask = Task { @MainActor in
            // Check cache first
            if let cached = await AdvancedCacheManager.image(for: imageKey) {
                loadedImage = cached
                return
            }
            
            // Load image
            isLoading = true
            
            if let image = await imageLoader() {
                await AdvancedCacheManager.setImage(image, for: imageKey)
                loadedImage = image
            }
            
            isLoading = false
        }
    }
    
    private func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
        isLoading = false
    }
}

// MARK: - Lazy Grid Performance Optimizations
struct OptimizedLazyGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let columns: [GridItem]
    let spacing: CGFloat?
    let content: (Data.Element) -> Content
    
    @State private var visibleRange: Range<Data.Index>
    
    init(
        data: Data,
        columns: [GridItem],
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.columns = columns
        self.spacing = spacing
        self.content = content
        
        // Initialize with first few items
        let endIndex = data.index(data.startIndex, offsetBy: min(20, data.count), limitedBy: data.endIndex) ?? data.endIndex
        self._visibleRange = State(initialValue: data.startIndex..<endIndex)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(data[visibleRange]), id: \.id) { item in
                content(item)
                    .onAppear {
                        expandVisibleRangeIfNeeded(for: item)
                    }
            }
        }
    }
    
    private func expandVisibleRangeIfNeeded(for item: Data.Element) {
        guard let index = data.firstIndex(where: { $0.id == item.id }) else { return }
        
        // Expand range if we're near the edges
        let rangeBuffer = 5
        let shouldExpand = data.distance(from: visibleRange.lowerBound, to: index) < rangeBuffer ||
                          data.distance(from: index, to: visibleRange.upperBound) < rangeBuffer
        
        if shouldExpand {
            let newStart = data.index(visibleRange.lowerBound, offsetBy: -rangeBuffer, limitedBy: data.startIndex) ?? data.startIndex
            let newEnd = data.index(visibleRange.upperBound, offsetBy: rangeBuffer, limitedBy: data.endIndex) ?? data.endIndex
            
            visibleRange = newStart..<newEnd
        }
    }
}

// MARK: - View Modifiers for Performance
struct ViewOffloadingModifier: ViewModifier {
    @State private var shouldRender = true
    
    func body(content: Content) -> some View {
        if shouldRender {
            content
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    shouldRender = false
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    shouldRender = true
                }
        } else {
            Rectangle()
                .fill(Color.clear)
                .frame(height: 1)
        }
    }
}

struct GeometryTrackingModifier: ViewModifier {
    let onChange: (CGSize) -> Void
    @State private var size: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: geometry.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { newSize in
                if newSize != size {
                    size = newSize
                    onChange(newSize)
                }
            }
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Performance-Optimized Components
struct OptimizedImageTile: View {
    let imageKey: String
    let size: CGSize
    let cornerRadius: CGFloat
    let imageLoader: () async -> UIImage?
    
    var body: some View {
        LazyImageView(
            imageKey: imageKey,
            aspectRatio: size.width / size.height,
            contentMode: .fill
        ) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemGray6))
                .frame(width: size.width, height: size.height)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.tertiary)
                        .font(.title2)
                )
        } imageLoader: {
            await imageLoader()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .modifier(ViewOffloadingModifier())
    }
}

struct OptimizedScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: () -> Content
    
    @State private var contentOffset: CGPoint = .zero
    @State private var isScrolling = false
    
    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content
    }
    
    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            content()
                .modifier(GeometryTrackingModifier { _ in
                    // Track scroll performance if needed
                })
        }
        .scrollDisabled(false)
        .onScrollGeometryChange(for: CGPoint.self) { geometry in
            geometry.contentOffset
        } action: { _, newValue in
            contentOffset = newValue
            
            // Optimize rendering during scrolling
            if !isScrolling {
                isScrolling = true
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    isScrolling = false
                }
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func optimizedForPerformance() -> some View {
        self.modifier(ViewOffloadingModifier())
    }
    
    func trackGeometry(onChange: @escaping (CGSize) -> Void) -> some View {
        self.modifier(GeometryTrackingModifier(onChange: onChange))
    }
    
    /// Reduces view updates by debouncing state changes
    func debounced<T: Equatable>(value: T, delay: TimeInterval = 0.3) -> some View {
        self.modifier(DebouncedModifier(value: value, delay: delay))
    }
}

private struct DebouncedModifier<T: Equatable>: ViewModifier {
    let value: T
    let delay: TimeInterval
    
    @State private var debouncedValue: T
    @State private var debounceTask: Task<Void, Never>?
    
    init(value: T, delay: TimeInterval) {
        self.value = value
        self.delay = delay
        self._debouncedValue = State(initialValue: value)
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, newValue in
                debounceTask?.cancel()
                debounceTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    if !Task.isCancelled {
                        debouncedValue = newValue
                    }
                }
            }
    }
}

#Preview {
    VStack {
        LazyImageView(
            imageKey: "test",
            aspectRatio: 1.0
        ) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 200)
        } imageLoader: {
            // Simulate async loading
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return UIImage(systemName: "photo.fill")
        }
        
        OptimizedScrollView(.vertical) {
            LazyVStack {
                ForEach(0..<100, id: \.self) { index in
                    Text("Item \(index)")
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .optimizedForPerformance()
                }
            }
        }
    }
}