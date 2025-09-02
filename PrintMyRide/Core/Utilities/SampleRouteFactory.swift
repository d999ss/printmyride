import CoreLocation
import Foundation

enum SampleRouteFactory {
    static func make() -> RoutePayload {
        let base = CLLocationCoordinate2D(latitude: 37.7735, longitude: -122.4230)
        let n = 500
        var coords: [CLLocationCoordinate2D] = []; coords.reserveCapacity(n)
        for i in 0..<n {
            let t = Double(i)/Double(n-1)
            let lat = base.latitude  + 0.010 * t + 0.002 * sin(t * .pi * 2)
            let lon = base.longitude + 0.015 * t + 0.001 * cos(t * .pi * 4)
            coords.append(.init(latitude: lat, longitude: lon))
        }
        var elev: [Double] = []; elev.reserveCapacity(n)
        for i in 0..<n {
            let t = Double(i)/Double(n-1)
            elev.append(30 + 70 * sin(t * .pi))   // 30–100m gentle hill
        }
        let start = Date()
        let times = (0..<n).map { start.addingTimeInterval(TimeInterval($0)) }
        return .init(coords: coords, elevations: elev, timestamps: times)
    }
}