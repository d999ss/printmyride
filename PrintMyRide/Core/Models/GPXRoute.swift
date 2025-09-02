import Foundation
import CoreLocation

struct GPXRoute: Codable {
    let points: [Point]
    let distanceMeters: Double
    let duration: TimeInterval?
    
    struct Point: Codable {
        let lat: Double
        let lon: Double
        let ele: Double?
        let t: Date?
        
        init(lat: Double, lon: Double, ele: Double? = nil, t: Date? = nil) {
            self.lat = lat
            self.lon = lon
            self.ele = ele
            self.t = t
        }
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
    
    var distanceInMiles: Double { distanceMeters / 1609.34 }
    var distanceInKilometers: Double { distanceMeters / 1000 }
    
    var durationInHours: Double? { duration.map { $0 / 3600 } }
    var durationInMinutes: Double? { duration.map { $0 / 60 } }
    
    var averageSpeed: Double? {
        guard let duration = duration, duration > 0 else { return nil }
        return distanceMeters / duration
    }
    
    var averageSpeedMPH: Double? { averageSpeed.map { $0 * 2.237 } }
    var averageSpeedKPH: Double? { averageSpeed.map { $0 * 3.6 } }
    
    var boundingBox: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        let lats = points.map { $0.lat }
        let lons = points.map { $0.lon }
        return (
            minLat: lats.min() ?? 0,
            maxLat: lats.max() ?? 0,
            minLon: lons.min() ?? 0,
            maxLon: lons.max() ?? 0
        )
    }
}
