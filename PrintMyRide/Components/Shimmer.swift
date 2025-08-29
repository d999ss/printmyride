import SwiftUI

struct Shimmer: View {
    @State private var phase: CGFloat = -1
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.25), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .mask(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(
                            colors: [.white, .white],
                            startPoint: .top, endPoint: .bottom))
                        .offset(x: phase * 200)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}