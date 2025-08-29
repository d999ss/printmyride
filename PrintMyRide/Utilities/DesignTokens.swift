import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // VSCO spacing tokens
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 24
    }
    
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        
        // VSCO radius token
        static let m: CGFloat = 12
    }
    
    enum Motion {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let smooth = Animation.easeInOut(duration: 0.35)
        static let gentle = Animation.easeInOut(duration: 0.5)
    }
    
    enum Typography {
        static let title = Font.largeTitle.weight(.bold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // VSCO font tokens
    enum FontToken {
        static var title: Font { .system(.title3, design: .default).weight(.semibold) }
        static var body: Font { .system(.body, design: .default) }
        static var footnote: Font { .system(.footnote, design: .default) }
        static var monoFootnote: Font { .system(.footnote, design: .monospaced) }
    }
    
    enum Colors {
        static let primary = Color.accentColor
        static let secondary = Color.secondary
        static let tertiary = Color(.tertiaryLabel)
        
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        static let separator = Color(.separator)
        static let label = Color(.label)
        static let secondaryLabel = Color(.secondaryLabel)
        
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }
    
    // VSCO color tokens
    enum ColorToken {
        static var bg: Color { Color(.systemBackground) }
        static var surface: Color { Color(.secondarySystemBackground) }
        static var label: Color { Color(.label) }
        static var secondary: Color { Color(.secondaryLabel) }
        static var accent: Color { Color(red: 0xFC/255, green: 0x4C/255, blue: 0x02/255) } // #FC4C02
    }
}

// VSCO BlurPill modifier
struct BlurPill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignTokens.Spacing.l)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.m, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

extension View {
    func blurPill() -> some View {
        modifier(BlurPill())
    }
}