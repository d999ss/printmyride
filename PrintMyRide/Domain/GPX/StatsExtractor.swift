import CoreLocation

enum StatsExtractor {
    struct Stats {
        let distanceKm: Double
        let ascentM: Double
        let durationSec: Double?
        var avgKmh: Double? { guard let dt = durationSec, dt > 0 else { return nil }
            return (distanceKm / (dt / 3600.0)) }
        let date: Date?
        
        static let zero = Stats(distanceKm: 0, ascentM: 0, durationSec: nil, date: nil)
    }
    
    /// Fully defensive. Empty or mismatched input never crashes.
    static func compute(coords: [CLLocationCoordinate2D]?,
                        elevations: [Double]?,
                        timestamps: [Date]?) -> Stats {
        let pts = coords ?? []
        guard pts.count > 1 else {
            PMRLog.export.log("[Stats] insufficient coords (\(pts.count))")
            return .zero
        }
        
        // Distance
        var distM = 0.0
        if pts.count > 1 {
            for i in 1..<pts.count { distM += haversine(pts[i-1], pts[i]) }
        }
        
        // Ascent
        var ascent: Double = 0
        if let elev = elevations, elev.count > 1 {
            for i in 1..<elev.count {
                let d = elev[i] - elev[i-1]
                if d > 0 { ascent += d }
            }
        }
        
        // Duration
        var durSec: Double? = nil
        if let ts = timestamps, ts.count > 1, let first = ts.first, let last = ts.last {
            durSec = max(0, last.timeIntervalSince(first))
        }
        
        // Date
        let date = timestamps?.first
        
        return Stats(distanceKm: distM/1000.0, ascentM: ascent, durationSec: durSec, date: date)
    }

    private static func haversine(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let R = 6_371_000.0
        let dLat = (b.latitude - a.latitude) * .pi/180
        let dLon = (b.longitude - a.longitude) * .pi/180
        let la1  = a.latitude * .pi/180, la2 = b.latitude * .pi/180
        let h = sin(dLat/2)*sin(dLat/2) + cos(la1)*cos(la2)*sin(dLon/2)*sin(dLon/2)
        return 2 * R * asin(min(1, sqrt(h)))
    }
}