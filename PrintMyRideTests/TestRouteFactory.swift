import CoreLocation
@testable import PrintMyRide

enum TestRouteFactory {
    static func line(count: Int = 50, dx: Double = 0.001, start: CLLocationCoordinate2D = .init(latitude: 40.0, longitude: -111.0)) -> [CLLocationCoordinate2D] {
        (0..<max(2, count)).map { i in
            .init(latitude: start.latitude + Double(i) * dx,
                  longitude: start.longitude + Double(i) * dx)
        }
    }

    static func zigzag(count: Int = 100, amp: Double = 0.001, period: Double = 10, start: CLLocationCoordinate2D = .init(latitude: 40.0, longitude: -111.0)) -> [CLLocationCoordinate2D] {
        (0..<max(2, count)).map { i in
            let t = Double(i)
            let lat = start.latitude + t * 0.0005
            let lon = start.longitude + sin(t/period) * amp
            return .init(latitude: lat, longitude: lon)
        }
    }
}