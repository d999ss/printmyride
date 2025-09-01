import SwiftUI
import MapKit
import CoreLocation

struct StudioHubView: View {
    @StateObject private var store = PosterStore()
    @EnvironmentObject private var services: ServiceHub
    @EnvironmentObject private var gate: SubscriptionGate
    @State private var toast: String?
    @StateObject private var favs = FavoritesStore.shared
    @State private var pressed = false
    @Namespace private var posterNS

    private let cols = [GridItem(.adaptive(minimum: 170), spacing: DesignTokens.Spacing.gridSpacing)]

    var body: some View {
        ToastHost(message: $toast) {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                demoGrid
            }
            // Give the banner breathing room and align grid with safe spacing
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }}
        .navigationTitle("Studio")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await seedIfNeeded()
            await ensureThumbnails()
        }
        .overlay(alignedCTA, alignment: .bottomTrailing)
    }
    
    private var header: some View {
        HeroBannerView(toast: $toast, onTryPro: tryPro)
            .environmentObject(gate)
    }


    private var demoGrid: some View {
        LazyVGrid(columns: cols, spacing: DesignTokens.Spacing.gridSpacing) {
            ForEach(Array(store.posters.enumerated()), id: \.element.id) { idx, poster in
                let coords = poster.coordinates ?? DemoCoordsLoader.coords(forTitle: poster.title)
                let isLockedPro = (idx == store.posters.count - 1) && !gate.isSubscribed

                // Card
                if isLockedPro {
                    Button {
                        tryPro()
                    } label: {
                        PosterCardView(
                            title: poster.title,
                            thumbPath: poster.thumbnailPath,
                            coords: coords,
                            locked: isLockedPro,
                            onShare: { sharePoster(poster) },
                            onFavorite: { favs.toggle(poster.id) },
                            isFavorite: favs.contains(poster.id),
                            matchedID: "poster-\(poster.id)",
                            ns: posterNS
                        )
                            .contentShape(Rectangle())
                            .scaleEffect(pressed ? 0.98 : 1.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: pressed)
                    }
                    .buttonStyle(CardPressStyle(pressed: $pressed))
                } else {
                    NavigationLink(destination: PosterDetailView(poster: poster).environmentObject(gate)) {
                        PosterCardView(
                            title: poster.title,
                            thumbPath: poster.thumbnailPath,
                            coords: coords,
                            locked: isLockedPro,
                            onShare: { sharePoster(poster) },
                            onFavorite: { favs.toggle(poster.id) },
                            isFavorite: favs.contains(poster.id),
                            matchedID: "poster-\(poster.id)",
                            ns: posterNS
                        )
                            .contentShape(Rectangle())
                            .scaleEffect(pressed ? 0.98 : 1.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: pressed)
                    }
                    .buttonStyle(CardPressStyle(pressed: $pressed))
                }
            }
        }
        .redacted(reason: store.posters.isEmpty ? .placeholder : [])
    }
    
    private func sharePoster(_ poster: Poster) {
        let url = store.imageURL(for: poster.filePath)
        if let img = UIImage(contentsOfFile: url.path) {
            PMRLog.ui.log("[Studio] share \(poster.title, privacy: .public)")
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
            ErrorBus.shared.report("[Studio] share failed (missing image)")
            toast = "Share failed - image not found"
            Haptics.error()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { toast = nil }
        }
    }

    private func seedIfNeeded() async {
        await store.bootstrap()
        if store.posters.isEmpty {
            // Seed 6 demo posters from bundled fixtures (names map in DemoCoordsLoader)
            let names = ["Park City Loop","Boulder Canyon Spin","City Night Ride","Coastal Sprint","Forest Switchbacks","Alpine Climb"]
            for n in names {
                let coords = DemoCoordsLoader.coords(forTitle: n)
                let full = await RouteRenderer.renderImage(from: coords, size: CGSize(width: 2500, height: 3500), lineWidth: 10)
                let thumb = await RouteRenderer.renderImage(from: coords, size: CGSize(width: 600, height: 840), lineWidth: 6)
                try? await PosterStoreWrapper(store: store).savePosterFromImages(title: n, full: full, thumb: thumb, coordinates: coords)
            }
            toast = "Loaded demo posters"
            PMRLog.ui.log("[Studio] seeded demo posters")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { toast = nil }
        }
    }

    private var alignedCTA: some View {
        Group {
            Button {
                Haptics.tap()
                if gate.isSubscribed { 
                    toast = "You're Pro already"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2){ toast = nil } 
                } else { 
                    PMRLog.paywall.log("[Studio] Try Pro tapped")
                    tryPro() 
                }
            } label: {
                Label(gate.isSubscribed ? "Pro Active" : "Try Pro", systemImage: "crown.fill")
                    .font(DesignTokens.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        Group {
                            if gate.isSubscribed {
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                LinearGradient(
                                    colors: [DesignTokens.Colors.accent, DesignTokens.Colors.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                    )
                    .clipShape(Capsule())
                    .shadow(
                        color: DesignTokens.Shadow.button.color,
                        radius: DesignTokens.Shadow.button.radius,
                        x: DesignTokens.Shadow.button.x,
                        y: DesignTokens.Shadow.button.y
                    )
            }
            .scaleEffect(pressed ? 0.95 : 1.0)
            .animation(DesignTokens.Animation.spring, value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
            .padding(DesignTokens.Spacing.md)
        }
    }

    private func tryPro() {
        Haptics.tap()
        toast = "Unlock hi-res exports"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { toast = nil }
    }

    // If a poster has no thumbnail yet (e.g., after a clean install), render one now so cards are never blank.
    private func ensureThumbnails() async {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for p in store.posters {
            let thumbURL = docs.appendingPathComponent(p.thumbnailPath)
            if !fm.fileExists(atPath: thumbURL.path) {
                let coords = p.coordinates ?? DemoCoordsLoader.coords(forTitle: p.title)
                // Prefer Apple Maps snapshot with route overlay
                if let snap = await withCheckedContinuation({ cont in
                    MapSnapshotService.snapshot(coords: coords, size: CGSize(width: 600, height: 840)) { cont.resume(returning: $0) }
                }) {
                    if let data = snap.jpegData(compressionQuality: 0.9) {
                        try? data.write(to: thumbURL, options: .atomic)
                    }
                } else {
                    // Fallback to route render if snapshot fails or coords empty
                    if let thumb = await RouteRenderer.renderImage(from: coords, size: CGSize(width: 600, height: 840), lineWidth: 6),
                       let data = thumb.jpegData(compressionQuality: 0.9) {
                        try? data.write(to: thumbURL, options: .atomic)
                    }
                }
            }
        }
    }
    
}