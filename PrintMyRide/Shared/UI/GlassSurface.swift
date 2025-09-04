import SwiftUI

// MARK: - Liquid Glass Surface Modifier with proper version gating
struct GlassSurface: ViewModifier {
    var corner: CGFloat = 22
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(liquidGlassBackground)
            .liquidGlassRounded(cornerRadius: corner)
    }
    
    @ViewBuilder
    private var liquidGlassBackground: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        
        if reduceTransparency {
            shape.fill(.quaternary)                           // accessibility fallback
        } else {
            // Use current iOS APIs - future Liquid Glass will be available in iOS 26+
            shape.fill(.ultraThinMaterial)
        }
    }
}

extension View {
    func glass(corner: CGFloat = 22) -> some View {
        modifier(GlassSurface(corner: corner))
    }
}