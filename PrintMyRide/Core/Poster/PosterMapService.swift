import MapKit

final class PosterMapService {
    static let shared = PosterMapService()
    private let cache = NSCache<NSString, UIImage>()

    func snapshot(for route: [CLLocationCoordinate2D],
                  spec: PosterSpec,
                  scale: CGFloat = 2.0) async throws -> UIImage {

        let routeHash = route.map { "\($0.latitude),\($0.longitude)" }.joined()
        let key = NSString(string: "map-\(routeHash.hashValue)-\(spec.hashValue)-\(scale)")
        if let cached = cache.object(forKey: key) { return cached }

        var region = MKCoordinateRegion(route)
        // pad so route stays inside safe zone
        let pad = max(spec.safeInset / spec.canvas.width, spec.safeInset / spec.canvas.height)
        region = region.padded(by: pad + 0.05)

        let size = spec.mapRect.size
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.scale = scale
        options.size = size
        
        // Use standard map type for compatibility
        options.mapType = .standard
        options.showsBuildings = false
        options.showsPointsOfInterest = false

        let snapshot = try await MKMapSnapshotter(options: options).start()
        let image = snapshot.image
        cache.setObject(image, forKey: key)
        return image
    }
}

private extension MKCoordinateRegion {
    init(_ coords: [CLLocationCoordinate2D]) {
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(latitude: (minLat+maxLat)/2, longitude: (minLon+maxLon)/2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat-minLat)*1.1, longitudeDelta: (maxLon-minLon)*1.1)
        self.init(center: center, span: span)
    }
    func padded(by pct: CGFloat) -> MKCoordinateRegion {
        MKCoordinateRegion(center: center,
                           span: MKCoordinateSpan(latitudeDelta: span.latitudeDelta*(1+pct*2),
                                                  longitudeDelta: span.longitudeDelta*(1+pct*2)))
    }
}