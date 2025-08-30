import SwiftUI

struct FullBleedPagerHero: View {
    let thumbs: [UIImage]
    let isLoading: Bool

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width, H = geo.size.height

            TabView {
                if isLoading || thumbs.isEmpty {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: W, height: H)
                        .clipped()
                        // still fade so layout looks correct during skeleton
                        .overlay(bottomFade)
                } else {
                    ForEach(Array(thumbs.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: W, height: H)
                            .clipped()
                            .overlay(bottomFade)          // ← fade into black
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))   // no dots
        }
    }

    // strong fade at the bottom so text/CTAs read on the wall
    private var bottomFade: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.85)],
            startPoint: .center, endPoint: .bottom
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}