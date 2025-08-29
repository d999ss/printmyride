import CoreLocation

enum StatsExtractor {
    struct Stats {
        let distanceKm: Double
        let ascentM: Double
        let durationSec: Double?
        var avgKmh: Double? { guard let dt = durationSec, dt > 0 else { return nil }
            return (distanceKm / (dt / 3600.0)) }
        let date: Date?
    }

    static func compute(from coords: [CLLocationCoordinate2D],
                        elevations: [Double] = [],
                        timestamps: [Date]? = nil) -> Stats {
        // Distance (haversine)
        var distM = 0.0
        for i in 1..<coords.count { distM += haversine(coords[i-1], coords[i]) }

        // Ascent (simple up-sum)
        var ascent: Double = 0
        if elevations.count > 1 {
            for i in 1..<elevations.count {
                let d = elevations[i] - elevations[i-1]
                if d > 0 { ascent += d }
            }
        }

        // Duration (if we have timestamps)
        var dur: Double? = nil
        if let ts = timestamps, let first = ts.first, let last = ts.last, ts.count > 1 {
            dur = last.timeIntervalSince(first)
        }

        // Date (use first timestamp if available)
        let date = timestamps?.first

        return .init(distanceKm: distM/1000.0, ascentM: ascent, durationSec: dur, date: date)
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