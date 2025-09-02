import SwiftUI

// MARK: - Semantic Roles
enum Role {
    case title, label, value, cardBG, accent, body
    case largeTitle, headline, subheadline, caption
    case button, card, surface
}

// MARK: - System-Native Theme
struct Theme {
    
    // MARK: - Typography (System First)
    static func font(_ role: Role) -> Font {
        switch role {
        case .largeTitle:
            return .largeTitle.weight(.bold)
        case .title:
            return .title2.weight(.semibold)
        case .headline:
            return .headline.weight(.semibold)
        case .label:
            return .subheadline
        case .value:
            return .title3.weight(.semibold)
        case .body:
            return .body
        case .subheadline:
            return .subheadline
        case .caption:
            return .caption.weight(.medium)
        default:
            return .body
        }
    }
    
    // MARK: - Colors (Semantic System Colors)
    static func color(_ role: Role) -> Color {
        switch role {
        case .title, .label, .value:
            return .primary
        case .body, .subheadline:
            return .primary
        case .caption:
            return .secondary
        case .accent:
            return .accentColor // Use system accent (respects global tint)
        case .cardBG:
            return Color(.systemBackground)
        case .surface:
            return Color(.secondarySystemBackground)
        default:
            return .primary
        }
    }
    
    // MARK: - Layout Tokens
    static let corner: CGFloat = 12.0
    static let spacing: CGFloat = 12.0
    static let cardPadding: CGFloat = 16.0
    static let gridSpacing: CGFloat = 14.0
    
    // MARK: - Component Sizes
    static let buttonHeight: CGFloat = 44.0
    static let cardCorner: CGFloat = 14.0
    static let sheetCorner: CGFloat = 16.0
    
    // MARK: - System Animations
    static let quickAnimation = Animation.easeInOut(duration: 0.2)
    static let standardAnimation = Animation.easeInOut(duration: 0.3)
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - System Component Extensions
extension View {
    
    /// Apply system card styling with material background
    func systemCard() -> some View {
        self
            .padding(Theme.cardPadding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
            .shadow(radius: 0) // Let material handle elevation
    }
    
    /// Apply system button styling with bordered prominent style
    func systemButton() -> some View {
        self.buttonStyle(.borderedProminent)
    }
    
    /// Apply native picker styling
    func systemPicker() -> some View {
        self.pickerStyle(.segmented)
    }
    
    /// Apply native list styling
    func systemList() -> some View {
        self.listStyle(.insetGrouped)
    }
}

// MARK: - System-Native Stat Card
struct SystemStatCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.font(.caption))
                .foregroundColor(.secondary)
            Text(value)
                .font(Theme.font(.value))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .systemCard()
    }
}

// MARK: - System Action Button
struct SystemActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(Theme.font(.caption))
            }
            .frame(maxWidth: .infinity, minHeight: Theme.buttonHeight + 12)
        }
        .systemCard()
        .buttonStyle(.plain)
    }
}