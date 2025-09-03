import SwiftUI

// MARK: - True Liquid Glass Surface Modifier
// Single material layer with proper glass treatment - no custom blur stacking
struct GlassSurface: ViewModifier {
    var corner: CGFloat = 22
    
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(.ultraThinMaterial) // system material only
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                // Subtle edge/specular highlight - not additional blur
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(.white.opacity(0.30), lineWidth: 0.8)
                    .blendMode(.overlay)
            )
            .shadow(radius: 16, x: 0, y: 10)                 // soft lift
            .shadow(color: .black.opacity(0.08), radius: 4)  // tight contact
            .compositingGroup()
    }
}

extension View {
    func glass(corner: CGFloat = 22) -> some View {
        modifier(GlassSurface(corner: corner))
    }
}