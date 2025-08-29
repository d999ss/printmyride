import SwiftUI

struct TextOverlay: View {
    let text: PosterText
    let stats: StatsExtractor.Stats?

    private var statsLine: String {
        var parts: [String] = []
        if text.showDistance, let s = stats { parts.append(String(format: "%.1f km", s.distanceKm)) }
        if text.showElevation, let s = stats { parts.append(String(format: "+%.0f m", s.ascentM)) }
        if text.showDate, let d = stats?.date {
            let f = DateFormatter(); f.dateStyle = .medium; parts.append(f.string(from: d))
        }
        return parts.joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            if !text.title.isEmpty {
                Text(text.title)
                    .font(.system(size: text.titleSizePt, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.label)
            }
            let sub = [text.subtitle, statsLine].filter{ !$0.isEmpty }.joined(separator: "\n")
            if !sub.isEmpty {
                Text(sub)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(.clear)
        .accessibilityIdentifier("overlay-text")
    }
}