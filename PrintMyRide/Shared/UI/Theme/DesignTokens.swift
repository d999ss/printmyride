import SwiftUI

enum DesignTokens {
    // MARK: - Colors
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let accent = Color.orange
        static let surface = Color(.systemBackground)
        static let onSurface = Color(.label)
        static let surfaceSecondary = Color(.secondarySystemBackground)
        static let onSurfaceSecondary = Color(.secondaryLabel)
        static let overlay = Color.black.opacity(0.6)
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
        
        // Semantic colors
        static let cardBackground = Color(.systemBackground)
        static let cardBorder = Color(.separator)
        static let shimmerBase = Color(.systemGray5)
        static let shimmerHighlight = Color(.systemGray4)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // Grid
        static let gridSpacing: CGFloat = 14
        static let cardPadding: CGFloat = 16
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let pill: CGFloat = 999
        
        // Component-specific
        static let card: CGFloat = 14
        static let button: CGFloat = 12
        static let sheet: CGFloat = 16
    }
    
    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let caption = Font.caption.weight(.medium)
        static let caption2 = Font.caption2
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let card = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
        static let button = (color: Color.black.opacity(0.15), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let sheet = (color: Color.black.opacity(0.2), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(10))
    }
    
    // MARK: - Animation
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let cardPress = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.9)
    }
}