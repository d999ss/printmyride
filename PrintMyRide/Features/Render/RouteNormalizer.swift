import CoreGraphics

struct RouteNormalizer {
    static func path(for route: GPXRoute, in content: CGRect) -> CGPath {
        guard !route.points.isEmpty else { return CGMutablePath() }
        let lats = route.points.map { $0.lat }
        let lons = route.points.map { $0.lon }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        
        let midLat = (minLat + maxLat) / 2.0
        let metersPerDegLat = 111_132.0
        let metersPerDegLon = metersPerDegLat * cos(midLat * .pi / 180)
        
        let widthMeters  = (maxLon - minLon) * metersPerDegLon
        let heightMeters = (maxLat - minLat) * metersPerDegLat
        
        let sx = content.width  / max(widthMeters, 1e-6)
        let sy = content.height / max(heightMeters, 1e-6)
        let scale = min(sx, sy) * 0.96
        
        let originX = content.midX
        let originY = content.midY
        
        let path = CGMutablePath()
        func pt(_ p: GPXRoute.Point) -> CGPoint {
            let xMeters = (p.lon - minLon) * metersPerDegLon - widthMeters / 2.0
            let yMeters = (p.lat - minLat) * metersPerDegLat - heightMeters / 2.0
            // y downwards for CoreGraphics
            return CGPoint(x: originX + CGFloat(xMeters) * CGFloat(scale),
                           y: originY - CGFloat(yMeters) * CGFloat(scale))
        }
        var iter = route.points.makeIterator()
        if let p0 = iter.next() { path.move(to: pt(p0)) }
        while let p = iter.next() { path.addLine(to: pt(p)) }
        return path
    }
}
