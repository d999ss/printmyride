import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var library: LibraryStore
    @State private var thumbs: [UIImage] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                
                // Full-bleed hero
                FullBleedPagerHero(thumbs: thumbs, isLoading: isLoading)
                    .frame(height: UIScreen.main.bounds.height * 0.65)
                    .ignoresSafeArea(edges: .top)

                // BIG LEFT-JUSTIFIED HEADLINE
                Text("Turn rides into art.")
                    .font(.system(size: 28, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .foregroundStyle(.white)

                VSCOPrimaryBar(title: "Get Started") {
                    library.hasSeenOnboarding = true
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 8)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await loadThumbs() }
    }

    // Build hero images from the sample route
    @MainActor private func loadThumbs() async {
        guard let r = SampleRoute.route() else { isLoading = false; return }
        let d = PosterDesign()
        let t = CGSize(width: 960, height: 1280)
        var imgs: [UIImage] = []
        if let a = Snapshotter.posterThumb(design: d, route: r, size: t) { imgs.append(a) }
        if let b = Snapshotter.posterThumb(design: d, route: r, size: t) { imgs.append(b) }
        if let c = Snapshotter.posterThumb(design: d, route: r, size: t) { imgs.append(c) }
        thumbs = imgs; isLoading = false
    }
}