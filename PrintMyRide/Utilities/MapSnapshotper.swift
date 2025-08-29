import SwiftUI
import MapKit

enum MapBackdropStyle: Int, CaseIterable {
    case standard, hybrid, satellite
}

enum MapSnapshotper {
    @MainActor
    static func snapshot(coords: [CLLocationCoordinate2D],
                         size: CGSize,
                         scale: CGFloat = UIScreen.main.scale,
                         style: MapBackdropStyle = .standard) async -> UIImage? {
        guard !coords.isEmpty, size.width > 1, size.height > 1 else { return nil }
        let opts = MKMapSnapshotter.Options()
        opts.region = RouteRegion.region(for: coords, padding: 0.12)
        opts.size = size
        opts.scale = scale
        switch style {
        case .standard:  opts.mapType = .standard
        case .hybrid:    opts.mapType = .hybrid
        case .satellite: opts.mapType = .satellite
        }
        // De-clutter POIs for a cleaner, VSCO feel
        if #available(iOS 16, *) { opts.pointOfInterestFilter = .excludingAll }

        let shot = MKMapSnapshotter(options: opts)
        do { return try await shot.start().image } catch { return nil }
    }
}