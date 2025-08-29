import SwiftUI
import CoreLocation

enum RenderMath {
    // Content rect in CURRENT view space (not DPI), using fractional margins (0–1)
    static func contentRect(in viewSize: CGSize, margins: CGFloat) -> CGRect {
        let m = max(0, min(margins, 0.49)) // never collapse
        let w = viewSize.width, h = viewSize.height
        return CGRect(x: w*m, y: h*m, width: w*(1 - 2*m), height: h*(1 - 2*m))
    }

    // Fit a source size into a destination rect, preserving aspect; return scale + top-left offset
    static func fit(_ src: CGSize, into dst: CGRect) -> (scale: CGFloat, origin: CGPoint) {
        guard src.width > 0, src.height > 0 else { return (1, CGPoint(x: dst.midX, y: dst.midY)) }
        let sx = dst.width / src.width
        let sy = dst.height / src.height
        let s = min(sx, sy)
        let fitted = CGSize(width: src.width * s, height: src.height * s)
        let ox = dst.minX + (dst.width  - fitted.width)  / 2
        let oy = dst.minY + (dst.height - fitted.height) / 2
        return (s, CGPoint(x: ox, y: oy))
    }

    // Equirectangular projection for small areas; returns points in an arbitrary planar space
    static func project(_ coords: [CLLocationCoordinate2D]) -> [CGPoint] {
        guard let first = coords.first else { return [] }
        let lat0 = coords.reduce(0.0, { $0 + $1.latitude }) / Double(max(coords.count,1))
        let kx = cos(lat0 * .pi/180)
        let minLat = coords.map(\.latitude).min() ?? first.latitude
        let minLon = coords.map(\.longitude).min() ?? first.longitude
        return coords.map { c in
            let x = (c.longitude - minLon) * kx
            let y = (c.latitude  - minLat)
            return CGPoint(x: x, y: y)
        }
    }

    static func bounds(of pts: [CGPoint]) -> CGRect {
        guard let f = pts.first else { return .zero }
        var minX = f.x, maxX = f.x, minY = f.y, maxY = f.y
        for p in pts {
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func cgCap(from cap: PosterDesign.LineCap) -> CGLineCap {
        switch cap {
        case .round: return .round
        case .square: return .square
        case .butt: return .butt
        }
    }
}