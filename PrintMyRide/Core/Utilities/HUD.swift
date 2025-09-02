import SwiftUI

struct InfoHUD: View {
    let paper: CGSize
    let dpi: Int
    let margins: CGFloat
    let grid: Double
    let pointsPre: Int
    let pointsPost: Int
    let zoomPercent: Int
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Label("\(Int(paper.width))×\(Int(paper.height)) in", systemImage: "rectangle.and.pencil.and.ellipsis")
                .font(DesignTokens.Typography.caption2)
            Text("\(dpi) dpi")
                .font(DesignTokens.Typography.caption2)
            Text("M \(Int(margins*100))%")
                .font(DesignTokens.Typography.caption2)
            Text("G \(Int(grid))pt")
                .font(DesignTokens.Typography.caption2)
            if zoomPercent != 100 {
                Text("\(zoomPercent)%")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.accent)
            }
            Text("pts \(pointsPost)/\(pointsPre)")
                .font(DesignTokens.Typography.caption2)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 1)
        .accessibilityIdentifier("hud")
    }
}

@MainActor
final class RenderStats {
    static let shared = RenderStats()
    var pointsPre = 0
    var pointsPost = 0
    var zoomPercent = 100
}