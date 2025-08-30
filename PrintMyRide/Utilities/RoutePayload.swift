import CoreLocation
import Foundation

struct RoutePayload {
    let coords: [CLLocationCoordinate2D]
    let elevations: [Double]
    let timestamps: [Date]
    var hasData: Bool { coords.count > 1 }
}