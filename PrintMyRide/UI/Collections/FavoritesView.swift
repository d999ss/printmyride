import SwiftUI
import CoreLocation

struct FavoritesView: View {
    @StateObject private var store = PosterStore()
    @StateObject private var favs = FavoritesStore.shared
    @EnvironmentObject private var gate: SubscriptionGate
    @State private var toast: String?
    @State private var pressed = false
    
    private let cols = [GridItem(.adaptive(minimum: 170), spacing: DesignTokens.Spacing.gridSpacing)]
    
    var body: some View {
        NavigationView {
            ToastHost(message: $toast) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        if favoritedPosters.isEmpty {
                            emptyState
                        } else {
                            collectionHeader
                            favoritesGrid
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                }
                .background(DesignTokens.Colors.surface)
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.large)
            .task { await store.bootstrap() }
        }
    }
    
    private var favoritedPosters: [Poster] {
        store.posters.filter { favs.contains($0.id) }
    }
    
    private var collectionHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Favorites")
                        .font(DesignTokens.Typography.title2)
                    
                    Text("\(favoritedPosters.count) poster\(favoritedPosters.count == 1 ? "" : "s") saved")
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
                
                Spacer()
                
                // Quick actions
                Menu {
                    Button {
                        shareCollection()
                    } label: {
                        Label("Share Collection", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        clearFavorites()
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundStyle(DesignTokens.Colors.primary)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }
    
    private var favoritesGrid: some View {
        LazyVGrid(columns: cols, spacing: DesignTokens.Spacing.gridSpacing) {
            ForEach(favoritedPosters) { poster in
                let coords = DemoCoordsLoader.coords(forTitle: poster.title)
                
                NavigationLink {
                    PosterDetailView(poster: poster)
                        .environmentObject(gate)
                } label: {
                    PosterCardView(
                        title: poster.title,
                        thumbPath: poster.thumbnailPath,
                        coords: coords,
                        locked: false,
                        onShare: { sharePoster(poster) },
                        onFavorite: { 
                            favs.toggle(poster.id)
                            Haptics.tap()
                            toast = "Removed from favorites"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
                        },
                        isFavorite: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    Button {
                        sharePoster(poster)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        favs.toggle(poster.id)
                        Haptics.tap()
                        toast = "Removed from favorites"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
                    } label: {
                        Label("Remove from Favorites", systemImage: "heart.slash")
                    }
                    
                    NavigationLink {
                        MockCheckoutView(poster: poster)
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                }
            }
        }
        .animation(DesignTokens.Animation.spring, value: favoritedPosters.count)
    }
    
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()
            
            VStack(spacing: DesignTokens.Spacing.md) {
                // Enhanced illustration with layered circles
                ZStack {
                    // Outer decorative circle
                    Circle()
                        .fill(DesignTokens.Colors.accent.opacity(0.1))
                        .frame(width: 140, height: 140)
                    
                    // Main background circle
                    Circle()
                        .fill(DesignTokens.Colors.surfaceSecondary)
                        .frame(width: 100, height: 100)
                        .shadow(
                            color: DesignTokens.Shadow.card.color,
                            radius: DesignTokens.Shadow.card.radius,
                            x: DesignTokens.Shadow.card.x,
                            y: DesignTokens.Shadow.card.y
                        )
                    
                    // Main icon with enhanced styling
                    ZStack {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(DesignTokens.Colors.surfaceSecondary)
                            .offset(x: 1, y: 1)
                        
                        Image(systemName: "heart")
                            .font(.system(size: 40))
                            .foregroundStyle(DesignTokens.Colors.accent.opacity(0.6))
                    }
                }
                .padding(.bottom, DesignTokens.Spacing.sm)
                
                Text("No Favorites Yet")
                    .font(DesignTokens.Typography.title2)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
                
                Text("Tap the heart icon on any poster to save it to your collection")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                
                // Enhanced CTA button with gradient
                NavigationLink {
                    // Navigate to Studio tab - this will be handled by the tab selection
                } label: {
                    Label("Browse Posters", systemImage: "square.grid.2x2")
                        .font(DesignTokens.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [DesignTokens.Colors.primary, DesignTokens.Colors.primary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button))
                        .shadow(
                            color: DesignTokens.Shadow.button.color,
                            radius: DesignTokens.Shadow.button.radius,
                            x: DesignTokens.Shadow.button.x,
                            y: DesignTokens.Shadow.button.y
                        )
                }
                .scaleEffect(pressed ? 0.98 : 1.0)
                .animation(DesignTokens.Animation.spring, value: pressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in pressed = true }
                        .onEnded { _ in pressed = false }
                )
                .padding(.top, DesignTokens.Spacing.sm)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    private func sharePoster(_ poster: Poster) {
        let url = store.imageURL(for: poster.filePath)
        if let img = UIImage(contentsOfFile: url.path) {
            PMRLog.ui.log("[Collections] share \(poster.title, privacy: .public)")
            let vc = UIActivityViewController(activityItems: [img], applicationActivities: nil)
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first?
                .present(vc, animated: true)
            
            // Enhanced toast with haptic feedback
            Haptics.tap()
            toast = "Sharing \(poster.title)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { toast = nil }
        } else {
            ErrorBus.shared.report("[Collections] share failed (missing image)")
            toast = "Share failed - image not found"
            Haptics.error()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { toast = nil }
        }
    }
    
    private func shareCollection() {
        let text = "Check out my PrintMyRide collection: \(favoritedPosters.count) amazing cycling route posters!"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first?
            .present(vc, animated: true)
        
        PMRLog.ui.log("[Collections] shared collection")
        Haptics.tap()
        toast = "Sharing your collection"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { toast = nil }
    }
    
    private func clearFavorites() {
        favoritedPosters.forEach { favs.toggle($0.id) }
        toast = "Favorites cleared"
        Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
        PMRLog.ui.log("[Collections] cleared all favorites")
    }
}