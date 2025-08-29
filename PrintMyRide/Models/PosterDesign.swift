// ──────────────────────────────────────────────────────────────
// DO NOT MODIFY — Canonical model used across the app.
// Any changes must be requested explicitly and reviewed.
// Tools: Claude/Cursor must only READ this API, never edit.
// ──────────────────────────────────────────────────────────────
import SwiftUI

// DO NOT MODIFY PosterDesign.swift. Treat it as frozen API.
// - No new types (e.g., Size, RGBAColor) — use CGSize and PosterDesign.ColorData.
// - Views may only READ PosterDesign or MUTATE via @Binding.
// - Prefer existing code; never output "keep all options."
// - Touch only CanvasSheet.swift, PosterPreview.swift, GridOverlay.swift for grid work.

struct PosterDesign: Equatable, Codable {
    // Canvas
    var paperSize: CGSize = .init(width: 18, height: 24) // inches
    var dpi: Int = 300
    var margins: CGFloat = 0.10                          // 0–1
    var orientation: Orientation = .portrait

    // Text
    var title: String = ""
    var subtitle: String = ""

    // Grid
    var showGrid: Bool = false
    var gridSpacing: Double = 50
    var gridColor: ColorData = .init(.gray.opacity(0.3))

    // Style
    var strokeWidthPt: CGFloat = 2.0
    var lineCap: LineCap = .round
    var dropShadowEnabled: Bool = false
    var dropShadowRadius: CGFloat = 12

    // Colors
    var routeColor: ColorData = .init(.black)
    var backgroundColor: ColorData = .init(.white)

    enum Orientation: String, Codable { case portrait, landscape }
    enum LineCap: String, Codable { case round, butt, square }

    struct ColorData: Codable, Equatable {
        var r: Double, g: Double, b: Double, a: Double
        init(_ color: Color) {
            #if canImport(UIKit)
            let ui = UIColor(color)
            var r: CGFloat=0,g:CGFloat=0,b:CGFloat=0,a:CGFloat=0
            ui.getRed(&r, green:&g, blue:&b, alpha:&a)
            self.r = Double(r); self.g = Double(g); self.b = Double(b); self.a = Double(a)
            #else
            self.r = 0; self.g = 0; self.b = 0; self.a = 1
            #endif
        }
        var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }
    }
}