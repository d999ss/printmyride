// ──────────────────────────────────────────────────────────────
// DO NOT MODIFY — Canonical overlay component.
// Tools: Claude/Cursor must only USE this view, never edit.
// ──────────────────────────────────────────────────────────────
import SwiftUI

struct GridOverlay: View {
    let spacing: Double
    let color: Color

    // Default values so old calls like GridOverlay() still compile
    init(spacing: Double = 40, color: Color = .secondary.opacity(0.3)) {
        self.spacing = spacing
        self.color = color
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Canvas { ctx, size in
                var path = Path()
                var x: CGFloat = 0
                while x <= w {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: h))
                    x += spacing
                }
                var y: CGFloat = 0
                while y <= h {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: w, y: y))
                    y += spacing
                }
                ctx.stroke(path, with: .color(color), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }
}
