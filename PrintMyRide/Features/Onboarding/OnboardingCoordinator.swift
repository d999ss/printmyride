import SwiftUI

struct OnboardingCoordinator: View {
    @StateObject private var model = OnboardingModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Consistent light background for glass effects
            Color(.systemBackground)
                .ignoresSafeArea()
            
            switch model.step {
            case .welcome:
                WelcomeScreen {
                    model.step = .connect
                }
                
            case .connect:
                ConnectScreen(
                    onStrava: {
                        await secureStep {
                            try await model.connectStrava()
                        }
                    },
                    onHealth: {
                        await secureStep {
                            try await model.connectHealth()
                        }
                    },
                    onImport: { url in
                        Task {
                            await secureStep {
                                try await model.importGPX(url)
                            }
                        }
                    },
                    onDemo: {
                        model.loadDemo()
                    }
                )
                
            case .permissions:
                PermissionsScreen {
                    model.step = .importing
                }
                
            case .importing:
                ImportingScreen()
                    .task {
                        await secureStep {
                            if model.rides.isEmpty {
                                try await model.importRecent()
                            }
                            try await model.buildPoster()
                            model.step = .posterPreview
                        }
                    }
                
            case .posterPreview:
                if let poster = model.poster {
                    PosterPreviewScreen(
                        poster: poster,
                        onSave: {
                            model.savePoster()
                        },
                        onShare: {
                            return model.sharePoster()
                        },
                        onContinue: {
                            model.step = .tips
                        }
                    )
                }
                
            case .tips:
                TipsScreen {
                    model.step = .done
                }
                
            case .done:
                DismissOnboardingView {
                    model.completeOnboarding()
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.light) // Liquid Glass optimized for light mode
        .alert("Error", isPresented: .constant(model.errorMessage != nil)) {
            Button("OK") {
                model.errorMessage = nil
            }
        } message: {
            if let error = model.errorMessage {
                Text(error)
            }
        }
    }
    
    @Sendable
    private func secureStep(_ work: @escaping () async throws -> Void) async {
        do {
            try await work()
        } catch {
            await MainActor.run {
                model.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Individual Screens

struct WelcomeScreen: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Hero
            VStack(spacing: 16) {
                Image(systemName: "bicycle")
                    .font(.system(size: 60))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
                
                Text("Make posters from your rides")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // CTA
            LiquidGlassCTA(title: "Get Started") {
                onContinue()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
    }
}

struct ConnectScreen: View {
    let onStrava: () async -> Void
    let onHealth: () async -> Void
    let onImport: (URL) -> Void
    let onDemo: () -> Void
    
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Text("Connect your rides")
                    .font(.title.weight(.semibold))
                
                Text("Choose where to import your cycling data")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Options
            VStack(spacing: 16) {
                // Primary: Strava
                AsyncButton(
                    title: "Connect Strava",
                    subtitle: "Most popular cycling platform",
                    icon: "figure.outdoor.cycle",
                    style: .primary
                ) {
                    await onStrava()
                }
                
                // Secondary: Apple Health
                AsyncButton(
                    title: "Apple Health",
                    subtitle: "From Apple Watch or iPhone",
                    icon: "heart.fill",
                    style: .secondary
                ) {
                    await onHealth()
                }
                
                // Tertiary: Import
                Button {
                    showingFilePicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import GPX/TCX")
                                .font(.headline)
                            Text("From Garmin, Wahoo, or other devices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Demo option
            Button("Try demo") {
                onDemo()
            }
            .font(.headline)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.xml, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    onImport(url)
                }
            case .failure:
                break
            }
        }
    }
}

struct PermissionsScreen: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Text("Quick permissions")
                    .font(.title.weight(.semibold))
                
                Text("We'll ask for a few permissions to make your experience better")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Permission items
            VStack(spacing: 20) {
                PermissionRow(
                    icon: "heart.fill",
                    title: "Health Data",
                    subtitle: "Read cycling workouts to build posters",
                    color: .red
                )
                
                PermissionRow(
                    icon: "photo.fill",
                    title: "Photos",
                    subtitle: "Save posters to your library",
                    color: Color(UIColor.systemBrown)
                )
                
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "We'll ping you when a new poster is ready",
                    color: .orange
                )
            }
            
            Spacer()
            
            LiquidGlassCTA(title: "Continue") {
                onContinue()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
    }
}

struct ImportingScreen: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Fetching rides…")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

struct PosterPreviewScreen: View {
    let poster: Poster
    let onSave: () -> Void
    let onShare: () -> UIImage?
    let onContinue: () -> Void
    
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Poster preview
            AsyncImage(url: URL(string: poster.thumbnailPath)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                    )
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Your first poster is ready!")
                .font(.title2.weight(.semibold))
            
            // Actions
            HStack(spacing: 16) {
                Button {
                    onSave()
                } label: {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    shareImage = onShare()
                    showingShareSheet = true
                } label: {
                    Text("Share")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            LiquidGlassCTA(title: "Continue") {
                onContinue()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                OnboardingShareSheet(items: [image])
            }
        }
    }
}

struct TipsScreen: View {
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.yellow)
                
                Text("Meet the Studio")
                    .font(.title.weight(.semibold))
                
                Text("Three simple tools to perfect your posters")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                TipRow(icon: "paintbrush.fill", text: "Edit style", color: .purple)
                TipRow(icon: "arrow.triangle.swap", text: "Change ride", color: Color(UIColor.systemBrown))
                TipRow(icon: "square.and.arrow.down.fill", text: "Save & share", color: .green)
            }
            
            Spacer()
            
            LiquidGlassCTA(title: "Start Creating") {
                onFinish()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
    }
}

struct DismissOnboardingView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)
            
            Text("All set!")
                .font(.largeTitle.weight(.bold))
                .padding(.top)
            
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }
}

// MARK: - Helper Views

struct LiquidGlassCTA: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .buttonStyle(LiquidGlassButtonStyle())
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(glassCapsule)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    @ViewBuilder
    private var glassCapsule: some View {
        Capsule()
            .fill(Color(UIColor.systemBrown).gradient)
            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.15), radius: 28, x: 0, y: 6)
    }
}

struct AsyncButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let style: Style
    let action: () async -> Void
    
    @State private var isLoading = false
    
    enum Style { case primary, secondary }
    
    var body: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return Color(UIColor.systemBrown).opacity(0.1)
        case .secondary: return Color(.quaternaryLabel)
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(text)
                .font(.headline)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct OnboardingShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}