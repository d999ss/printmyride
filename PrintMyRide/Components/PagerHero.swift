import SwiftUI

struct PagerHero: View {
    let thumbs: [UIImage]
    let isLoading: Bool

    var body: some View {
        if isLoading || thumbs.isEmpty {
            // 3 shimmer pages
            TabView {
                ForEach(0..<3, id: \.self) { _ in ShimmerPage() }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        } else {
            TabView {
                ForEach(Array(thumbs.enumerated()), id: \.offset) { _, img in
                    GeometryReader { geo in
                        let minX = geo.frame(in: .global).minX
                        let parallax = min(max(minX / 60, -8), 8) // subtle
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(3/4, contentMode: .fit)
                            .padding(.horizontal, 20)
                            .offset(x: -parallax)               // gentle parallax
                            .scaleEffect(1 - abs(minX)/4000)    // whisper zoom
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }
}

private struct ShimmerPage: View {
    var body: some View {
        Rectangle()
            .fill(Color(.secondarySystemBackground))
            .padding(.horizontal, 20)
            .overlay(ShimmerBand())
    }
}

private struct ShimmerBand: View {
    @State private var x: CGFloat = -260
    var body: some View {
        LinearGradient(colors: [.clear,.white.opacity(0.25),.clear],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(width: 220)
            .offset(x: x)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    x = 260
                }
            }
    }
}