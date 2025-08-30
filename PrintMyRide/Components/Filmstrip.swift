import SwiftUI

struct Filmstrip: View {
    let thumbs: [UIImage]
    let isLoading: Bool

    private let cardW: CGFloat = 160
    private let cardH: CGFloat = 213.3333 // 3:4

    var body: some View {
        GeometryReader { geo in
            let side = max(12, (geo.size.width - cardW)/2)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    Color.clear.frame(width: side) // leading inset

                    if isLoading || thumbs.isEmpty {
                        ForEach(0..<3, id: \.self) { _ in ShimmerCard() }
                    } else {
                        ForEach(Array(thumbs.enumerated()), id: \.offset) { _, img in
                            PosterCard(image: img)
                        }
                    }

                    Color.clear.frame(width: side) // trailing inset
                }
            }
        }
    }
}

struct ShimmerCard: View {
    var body: some View {
        Rectangle()
            .fill(Color(.secondarySystemBackground))
            .frame(width: 160, height: 213.3333)
            .overlay(
                LinearGradient(colors: [.clear,.white.opacity(0.25),.clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .mask(
                        Rectangle()
                            .fill(.white)
                            .offset(x: -200)
                            .modifier(ShimmerAnim())
                    )
            )
    }
}

struct ShimmerAnim: ViewModifier {
    @State private var x: CGFloat = -200
    func body(content: Content) -> some View {
        content
            .offset(x: x)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    x = 200
                }
            }
    }
}