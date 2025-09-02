import Foundation
import MapKit
import CoreLocation

enum RouteMapHelpers {
    static func polyline(from coords: [CLLocationCoordinate2D]) -> MKPolyline {
        MKPolyline(coordinates: coords, count: coords.count)
    }
    static func region(fitting coords: [CLLocationCoordinate2D], padding: CLLocationDegrees = 0.01) -> MKCoordinateRegion {
        guard let minLat = coords.map(\.latitude).min(),
              let maxLat = coords.map(\.latitude).max(),
              let minLon = coords.map(\.longitude).min(),
              let maxLon = coords.map(\.longitude).max()
        else {
            return MKCoordinateRegion(.world)
        }
        let span = MKCoordinateSpan(latitudeDelta: max(0.002, (maxLat-minLat) + padding),
                                    longitudeDelta: max(0.002, (maxLon-minLon) + padding))
        let center = CLLocationCoordinate2D(latitude: (minLat+maxLat)/2.0, longitude: (minLon+maxLon)/2.0)
        return MKCoordinateRegion(center: center, span: span)
    }
}