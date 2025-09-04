import SwiftUI

/// Reusable Liquid Glass surface with proper version gating and accessibility support
struct LiquidGlassCapsule: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    var body: some View {
        if reduceTransparency {
            Capsule().fill(.quaternary)                   // accessibility fallback
        } else {
            // Use current iOS APIs - future Liquid Glass will be available in iOS 26+
            Capsule().fill(.ultraThinMaterial)
        }
    }
}

/// Reusable Liquid Glass surface for rounded rectangles
struct LiquidGlassRoundedRectangle: View {
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        
        if reduceTransparency {
            shape.fill(.quaternary)                       // accessibility fallback
        } else {
            // Use current iOS APIs - future Liquid Glass will be available in iOS 26+
            shape.fill(.ultraThinMaterial)
        }
    }
}

/// View modifier for applying Liquid Glass styling with proper shadows and strokes
extension View {
    func liquidGlass<S: Shape>(
        shape: S,
        strokeOpacity: Double = 0.22,
        shadowOpacity: Double = 0.15,
        shadowRadius: CGFloat = 28,
        shadowOffset: CGSize = CGSize(width: 0, height: 6)
    ) -> some View {
        self
            .overlay(shape.stroke(.white.opacity(strokeOpacity), lineWidth: 1))
            .shadow(
                color: .black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
    }
}

/// Convenience modifiers for common shapes
extension View {
    func liquidGlassCapsule(
        strokeOpacity: Double = 0.22,
        shadowOpacity: Double = 0.15
    ) -> some View {
        self.liquidGlass(
            shape: Capsule(),
            strokeOpacity: strokeOpacity,
            shadowOpacity: shadowOpacity
        )
    }
    
    func liquidGlassRounded(
        cornerRadius: CGFloat = 16,
        strokeOpacity: Double = 0.22,
        shadowOpacity: Double = 0.15
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self.liquidGlass(
            shape: shape,
            strokeOpacity: strokeOpacity,
            shadowOpacity: shadowOpacity
        )
    }
}