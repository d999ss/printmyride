import Foundation
import MapKit
import UIKit
import SwiftUI

final class MapSnapshotService {
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
                    
                    let result = await ImageRenderer(content: routeOverlay).uiImage
                    
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