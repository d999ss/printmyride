import CoreLocation
import MapKit

enum RouteRegion {
    static func region(for coords: [CLLocationCoordinate2D], padding: Double = 0.15) -> MKCoordinateRegion {
        guard let first = coords.first else {
            return MKCoordinateRegion(center: .init(latitude: 0, longitude: 0),
                                      span: .init(latitudeDelta: 1, longitudeDelta: 1))
        }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let latSpan = max(0.001, maxLat - minLat)
        let lonSpan = max(0.001, maxLon - minLon)
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: latSpan * (1 + padding * 2),
                                    longitudeDelta: lonSpan * (1 + padding * 2))
        return MKCoordinateRegion(center: center, span: span)
    }
}