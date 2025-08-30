import UIKit
import MapKit
import CoreLocation

enum MapKitPoster {
    static func snapshot(coords: [CLLocationCoordinate2D],
                         size: CGSize,
                         terrain: MapTerrain) async -> UIImage? {
        guard coords.count > 1, size.width > 2, size.height > 2 else { return nil }

        var minLat = coords[0].latitude, maxLat = minLat
        var minLon = coords[0].longitude, maxLon = minLon
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let pad = 0.12
        let center = CLLocationCoordinate2D(latitude: (minLat+maxLat)/2,
                                            longitude: (minLon+maxLon)/2) // ✅ correct
        let span = MKCoordinateSpan(latitudeDelta: max(0.001,(maxLat-minLat))*(1+pad*2),
                                    longitudeDelta: max(0.001,(maxLon-minLon))*(1+pad*2))
        let region = MKCoordinateRegion(center: center, span: span)

        let opts = MKMapSnapshotter.Options()
        opts.region  = region
        opts.size    = size

        // Get scale on main actor to avoid isolation warning
        let scale: CGFloat = await MainActor.run { UIScreen.main.scale }
        opts.scale   = scale
        opts.mapType = terrain.mapType
        if #available(iOS 16, *) { opts.pointOfInterestFilter = .excludingAll }
        if #available(iOS 13, *) { opts.traitCollection = UITraitCollection(userInterfaceStyle: .light) }

        do {
            let snapshotter = MKMapSnapshotter(options: opts)
            let result = try await snapshotter.start() // ✅ proper await
            return result.image
        } catch {
            return nil
        }
    }
    
    // Keep the old signature for backward compatibility
    static func snapshot(coords: [CLLocationCoordinate2D],
                         size: CGSize,
                         mapType: MKMapType = .mutedStandard) async -> UIImage? {
        let terrain: MapTerrain = mapType == .standard ? .standard : 
                                 mapType == .hybrid ? .hybrid : .muted
        return await snapshot(coords: coords, size: size, terrain: terrain)
    }
    
    // New overload for MKMapType parameter directly
    static func snapshot(coords: [CLLocationCoordinate2D],
                         size: CGSize,
                         terrain: MKMapType) async -> UIImage? {
        guard coords.count > 1, size.width > 2, size.height > 2 else { return nil }

        var minLat = coords[0].latitude, maxLat = minLat
        var minLon = coords[0].longitude, maxLon = minLon
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let pad = 0.12
        let center = CLLocationCoordinate2D(latitude: (minLat+maxLat)/2,
                                            longitude: (minLon+maxLon)/2)
        let span = MKCoordinateSpan(latitudeDelta: max(0.001,(maxLat-minLat))*(1+pad*2),
                                    longitudeDelta: max(0.001,(maxLon-minLon))*(1+pad*2))
        let region = MKCoordinateRegion(center: center, span: span)

        let opts = MKMapSnapshotter.Options()
        opts.region  = region
        opts.size    = size

        // Get scale on main actor to avoid isolation warning
        let scale: CGFloat = await MainActor.run { UIScreen.main.scale }
        opts.scale   = scale
        opts.mapType = terrain
        if #available(iOS 16, *) { opts.pointOfInterestFilter = .excludingAll }
        if #available(iOS 13, *) { opts.traitCollection = UITraitCollection(userInterfaceStyle: .light) }

        do {
            let snapshotter = MKMapSnapshotter(options: opts)
            let result = try await snapshotter.start()
            return result.image
        } catch {
            return nil
        }
    }
}