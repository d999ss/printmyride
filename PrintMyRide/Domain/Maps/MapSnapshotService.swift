import Foundation
import MapKit
import UIKit
import SwiftUI

final class MapSnapshotService {
    
    /// Robust map snapshot with proper region handling and OS version guards
    static func pmrSnapshotKnownGood(
        coords: [CLLocationCoordinate2D],
        size: CGSize,
        style: Int  // 0 standard, 1 hybrid, 2 satellite
    ) async -> UIImage? {
        guard !coords.isEmpty, size.width > 20, size.height > 20 else { 
            // Invalid input parameters
            return nil 
        }

        // Build a safe region (min span guards)
        var minLat =  90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let pad = 0.10
        let span = MKCoordinateSpan(
            latitudeDelta:  max(0.0005, maxLat - minLat) * (1 + pad*2),
            longitudeDelta: max(0.0005, maxLon - minLon) * (1 + pad*2)
        )
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat)/2, longitude: (minLon + maxLon)/2)

        // Generating map snapshot

        // Options guarded by OS version
        let opts = MKMapSnapshotter.Options()
        opts.size = size
        opts.region = MKCoordinateRegion(center: center, span: span)
        opts.showsBuildings = false
        opts.pointOfInterestFilter = .excludingAll

        if #available(iOS 17.0, *) {
            switch style {
            case 1: opts.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: .flat)
            case 2: opts.preferredConfiguration = MKImageryMapConfiguration(elevationStyle: .flat)
            default: opts.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
            }
        } else {
            opts.mapType = (style == 1) ? .hybrid : (style == 2 ? .satellite : .standard)
        }

        // Run snapshotter
        return await withCheckedContinuation { cont in
            MKMapSnapshotter(options: opts).start { snap, err in
                guard let snap = snap, err == nil else { 
                    // Map snapshot failed
                    cont.resume(returning: nil)
                    return 
                }
                
                // Tone down slightly so the route pops
                let r = UIGraphicsImageRenderer(size: size)
                let img = r.image { ctx in
                    snap.image.draw(at: .zero)
                    UIColor.black.withAlphaComponent(0.22).setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                }
                
                // Map snapshot generated successfully
                cont.resume(returning: img)
            }
        }
    }
    
    static func snapshot(coords: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        guard !coords.isEmpty else { return nil }
        
        // Generate cache key from coordinates and size
        let cacheKey = generateCacheKey(coords: coords, size: size)
        
        // Check cache first
        if let cachedImage = ImageCache.shared.image(for: cacheKey) {
            return cachedImage
        }
        
        return await withCheckedContinuation { continuation in
            let options = MKMapSnapshotter.Options()
            options.region = RouteMapHelpers.region(fitting: coords)
            options.size = size
            options.showsBuildings = false
            options.pointOfInterestFilter = .excludingAll
            
            let snap = MKMapSnapshotter(options: options)
            snap.start { image, error in
                Task { @MainActor in
                    guard let base = image?.image, error == nil else { 
                        continuation.resume(returning: nil)
                        return 
                    }
                    
                    let routeOverlay = RouteOverlayView(
                        baseImage: base, 
                        coords: coords, 
                        mapImage: image!,
                        size: size
                    )
                    
                    let result = ImageRenderer(content: routeOverlay).uiImage
                    
                    // Cache the result
                    if let image = result {
                        ImageCache.shared.setImage(image, for: cacheKey)
                    }
                    
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    // Legacy completion-based method for backward compatibility
    static func snapshot(coords: [CLLocationCoordinate2D], size: CGSize, completion: @escaping (UIImage?) -> Void) {
        Task {
            let result = await snapshot(coords: coords, size: size)
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    private static func generateCacheKey(coords: [CLLocationCoordinate2D], size: CGSize) -> String {
        let coordsHash = coords.prefix(10).map { "\($0.latitude),\($0.longitude)" }.joined(separator: "_")
        return "map_\(coordsHash)_\(Int(size.width))x\(Int(size.height))"
    }
}

private struct RouteOverlayView: View {
    let baseImage: UIImage
    let coords: [CLLocationCoordinate2D]
    let mapImage: MKMapSnapshotter.Snapshot
    let size: CGSize
    
    var body: some View {
        Canvas { context, canvasSize in
            // Draw base map
            if let resolvedImage = context.resolveSymbol(id: "baseMap") {
                context.draw(resolvedImage, at: CGPoint(x: canvasSize.width/2, y: canvasSize.height/2))
            }
            
            // Draw route overlay
            let path = Path { path in
                var first = true
                for coord in coords {
                    let point = mapImage.point(for: coord)
                    if first {
                        path.move(to: point)
                        first = false
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
            
            // Route with glow effect
            context.addFilter(.shadow(color: .black.opacity(0.6), radius: 8))
            context.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
        .frame(width: size.width, height: size.height)
        .background {
            Image(uiImage: baseImage)
                .resizable()
                .scaledToFill()
        }
    }
}