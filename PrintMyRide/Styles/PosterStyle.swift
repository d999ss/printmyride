import SwiftUI
import MapKit

enum PosterLayout: String, Codable { case classic, gallery }

struct Margins: Codable {
    var sidePct: CGFloat   // e.g. 0.10
    var vPct: CGFloat      // e.g. 0.03
    var minSide: CGFloat   // pts
    var maxSide: CGFloat
    var minV: CGFloat
    var maxV: CGFloat
}
struct MapConfig: Codable {
    var terrain: String      // "muted" | "standard" | "hybrid"
    var muteOpacity: CGFloat // 0...1
    var hideWatermark: Bool
}
struct TicksConfig: Codable {
    var enabled: Bool
    var spacingRel: CGFloat  // relative to polyline count (e.g. 0.016)
    var size: CGFloat        // pt
    var opacity: CGFloat     // 0...1
}
enum MarkerStyle: String, Codable { case filled, ring }
struct RouteConfig: Codable {
    var colorHex: String     // e.g. "#FC4C02"
    var widthRel: CGFloat    // e.g. 0.006 of poster width
    var ticks: TicksConfig
    var start: MarkerStyle
    var finish: MarkerStyle
}
struct Typography: Codable {
    var titleSize: CGFloat
    var titleWeight: String  // "regular"|"semibold"|"bold"
    var captionSize: CGFloat // gallery caption font size
}
struct CaptionConfig: Codable {
    var tokens: [String]     // e.g. ["distance","elevation","days","weather"]
    var bullet: String       // "•"
    var maxWidthPct: CGFloat // e.g. 0.82
    var gapToTitle: CGFloat  // pt (e.g. 4)
    var bottomSpacePct: CGFloat // e.g. 0.08
}
struct FooterConfig: Codable {
    var enabled: Bool        // classic only
    var paddingH: CGFloat    // 26
    var paddingV: CGFloat    // 12
}

struct Colors: Codable {
    var paper: String      // e.g. "#FFFFFF"
    var panel: String      // inner panel behind map/title/caption (for dark styles)
    var title: String
    var caption: String
}

struct PosterStyle: Identifiable, Codable {
    var id: String
    var name: String
    var layout: PosterLayout
    var margins: Margins
    var map: MapConfig
    var route: RouteConfig
    var typography: Typography
    var caption: CaptionConfig?
    var footer: FooterConfig?
    var colors: Colors
}

// helpers
extension PosterStyle {
    var terrain: MKMapType {
        switch map.terrain {
        case "standard": return .standard
        case "hybrid":   return .hybrid
        default:         return .mutedStandard
        }
    }
    var routeColor: Color {
        Color(hex: route.colorHex) ?? Color(red: 0xFC/255, green: 0x4C/255, blue: 0x02/255)
    }
    var paperColor: Color   { Color(hex: colors.paper)   ?? .white }
    var panelColor: Color   { Color(hex: colors.panel)   ?? .white }
    var titleColor: Color   { Color(hex: colors.title)   ?? .black }
    var captionColor: Color { Color(hex: colors.caption) ?? .black.opacity(0.8) }
}
extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle rgba() format
        if s.hasPrefix("rgba(") && s.hasSuffix(")") {
            let rgba = String(s.dropFirst(5).dropLast(1))
            let components = rgba.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            guard components.count == 4 else { return nil }
            self = Color(red: components[0]/255.0, green: components[1]/255.0, blue: components[2]/255.0, opacity: components[3])
            return
        }
        
        // Handle hex format
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = Int(s, radix:16) else { return nil }
        self = Color(red: Double((v>>16)&0xFF)/255.0,
                     green: Double((v>>8)&0xFF)/255.0,
                     blue: Double(v&0xFF)/255.0)
    }
}