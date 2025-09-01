import SwiftUI

struct ShimmerEffect: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            colors: [
                DesignTokens.Colors.shimmerBase,
                DesignTokens.Colors.shimmerHighlight,
                DesignTokens.Colors.shimmerBase
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .scaleEffect(x: 3, y: 1, anchor: .leading)
        .offset(x: phase)
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                phase = 400
            }
        }
    }
}

struct ShimmerModifier: ViewModifier {
    let isShimmering: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                isShimmering ? ShimmerEffect().clipped() : nil
            )
            .opacity(isShimmering ? 0.8 : 1.0)
    }
}

extension View {
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isShimmering: isActive))
    }
}

// MARK: - Shimmer Placeholders

struct ShimmerPosterCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Image placeholder
            Rectangle()
                .fill(DesignTokens.Colors.shimmerBase)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card))
                .shimmer()
            
            // Title placeholder
            Rectangle()
                .fill(DesignTokens.Colors.shimmerBase)
                .frame(height: 16)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
                .shimmer()
            
            // Metrics placeholder
            HStack(spacing: DesignTokens.Spacing.sm) {
                Rectangle()
                    .fill(DesignTokens.Colors.shimmerBase)
                    .frame(width: 60, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
                    .shimmer()
                
                Rectangle()
                    .fill(DesignTokens.Colors.shimmerBase)
                    .frame(width: 50, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
                    .shimmer()
                
                Spacer()
            }
        }
    }
}

struct ShimmerText: View {
    let width: CGFloat
    let height: CGFloat
    
    init(width: CGFloat = 100, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Rectangle()
            .fill(DesignTokens.Colors.shimmerBase)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
            .shimmer()
    }
}