import SwiftUI
import UIKit
import MapKit
import os.log

/// High-performance poster renderer with aggressive optimizations
actor PosterRenderService {
    private static let logger = Logger(subsystem: "PMR", category: "PosterRender")
    private var renderCache: [String: UIImage] = [:]
    private let maxCacheSize = 50
    
    // MARK: - Optimized Render Pipeline
    
    func renderPoster(design: PosterDesign, route: GPXRoute?, size: CGSize, quality: RenderQuality = .standard) async -> UIImage? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate cache key
        let cacheKey = generateCacheKey(design: design, route: route, size: size, quality: quality)
        
        // Check cache first
        if let cached = renderCache[cacheKey] {
            Self.logger.info("Cache hit for poster render: \((CFAbsoluteTimeGetCurrent() - startTime) * 1000)ms")
            return cached
        }
        
        // Parallel render pipeline
        async let mapSnapshotTask = renderMapSnapshot(coords: route?.coordinates ?? [], size: size, quality: quality)
        async let routePathTask = renderRoutePath(coords: route?.coordinates ?? [], design: design, size: size)
        
        let (mapSnapshot, routePath) = await (mapSnapshotTask, routePathTask)
        
        // Composite final image
        let result = await compositePoster(
            background: design.backgroundColor,
            mapSnapshot: mapSnapshot,
            routePath: routePath,
            design: design,
            size: size
        )
        
        // Cache result
        if let result = result {
            await cacheResult(result, for: cacheKey)
        }
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        Self.logger.info("Poster render completed: \(duration)ms")
        
        return result
    }
    
    // MARK: - Optimized Map Snapshots
    
    private func renderMapSnapshot(coords: [CLLocationCoordinate2D], size: CGSize, quality: RenderQuality) async -> UIImage? {
        guard !coords.isEmpty else { return nil }
        
        // Use lower resolution for previews
        let actualSize = quality == .preview ? 
            CGSize(width: size.width * 0.5, height: size.height * 0.5) : size
        
        return await MapSnapshotper.snapshot(
            coords: coords,
            size: actualSize,
            scale: quality.scale,
            style: .standard
        )
    }
    
    // MARK: - Optimized Route Path Generation
    
    private func renderRoutePath(coords: [CLLocationCoordinate2D], design: PosterDesign, size: CGSize) async -> UIImage? {
        guard !coords.isEmpty else { return nil }
        
        return await withCheckedContinuation { continuation in
            // Offload to background queue
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: size)
                let result = renderer.image { context in
                    self.drawOptimizedRoute(
                        coords: coords,
                        design: design,
                        context: context,
                        size: size
                    )
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Optimized Route Drawing
    
    private func drawOptimizedRoute(coords: [CLLocationCoordinate2D], design: PosterDesign, context: UIGraphicsImageRendererContext, size: CGSize) {
        // Convert to points with optimized projection
        let region = RouteRegion.region(for: coords, padding: 0.1)
        let projector = EquirectangularProjector(region: region)
        
        var points = coords.map { projector.project($0) }
        
        // Aggressive simplification for large routes
        let targetPoints = min(2000, coords.count)
        if points.count > targetPoints {
            points = Simplify.rdp(points, epsilon: 0.001)
            points = Simplify.budget(points, maxPoints: targetPoints)
        }
        
        // Scale to canvas
        let bbox = points.boundingBox()
        let contentRect = RenderMath.contentRect(in: size, margins: design.margins)
        let transform = CGAffineTransform.scaling(from: bbox, to: contentRect)
        
        points = points.map { $0.applying(transform) }
        
        // Draw with optimized path
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        ctx.setStrokeColor(design.routeColor.cgColor)
        ctx.setLineWidth(design.strokeWidthPt)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        
        // Use single path for better performance
        ctx.beginPath()
        if let first = points.first {
            ctx.move(to: first)
            for point in points.dropFirst() {
                ctx.addLine(to: point)
            }
        }
        ctx.strokePath()
    }
    
    // MARK: - Final Composition
    
    @MainActor
    private func compositePoster(background: Color, mapSnapshot: UIImage?, routePath: UIImage?, design: PosterDesign, size: CGSize) async -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Background
            ctx.setFillColor(UIColor(background).cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Map snapshot (if enabled)
            if let snapshot = mapSnapshot, design.showMapBackground {
                ctx.draw(snapshot.cgImage!, in: CGRect(origin: .zero, size: size))
            }
            
            // Route overlay
            if let route = routePath {
                ctx.draw(route.cgImage!, in: CGRect(origin: .zero, size: size), byTiling: false)
            }
        }
    }
    
    // MARK: - Cache Management
    
    private func cacheResult(_ image: UIImage, for key: String) async {
        renderCache[key] = image
        
        // LRU eviction
        if renderCache.count > maxCacheSize {
            let oldestKey = renderCache.keys.first!
            renderCache.removeValue(forKey: oldestKey)
        }
    }
    
    private func generateCacheKey(design: PosterDesign, route: GPXRoute?, size: CGSize, quality: RenderQuality) -> String {
        let routeHash = route?.coordinates.prefix(10).map { "\($0.latitude),\($0.longitude)" }.joined(separator: "_") ?? "no-route"
        return "\(design.hashValue)_\(routeHash)_\(Int(size.width))x\(Int(size.height))_\(quality.rawValue)"
    }
}

// MARK: - Supporting Types

enum RenderQuality: String, CaseIterable {
    case preview, standard, export
    
    var scale: CGFloat {
        switch self {
        case .preview: return 1.0
        case .standard: return 2.0
        case .export: return 3.0
        }
    }
}

struct EquirectangularProjector {
    let region: MKCoordinateRegion
    private let centerLat: Double
    private let kx: Double
    
    init(region: MKCoordinateRegion) {
        self.region = region
        self.centerLat = region.center.latitude
        self.kx = cos(centerLat * .pi / 180)
    }
    
    func project(_ coord: CLLocationCoordinate2D) -> CGPoint {
        return CGPoint(
            x: (coord.longitude - region.center.longitude) * kx,
            y: coord.latitude - region.center.latitude
        )
    }
}

extension Array where Element == CGPoint {
    func boundingBox() -> CGRect {
        guard !isEmpty else { return .zero }
        let xs = map(\.x)
        let ys = map(\.y)
        return CGRect(
            x: xs.min()!,
            y: ys.min()!,
            width: xs.max()! - xs.min()!,
            height: ys.max()! - ys.min()!
        )
    }
}

extension CGAffineTransform {
    static func scaling(from source: CGRect, to target: CGRect) -> CGAffineTransform {
        let sx = target.width / source.width
        let sy = target.height / source.height
        let scale = min(sx, sy)
        
        let dx = target.midX - source.midX * scale
        let dy = target.midY - source.midY * scale
        
        return CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: dx, y: dy)
    }
}

extension PosterDesign {
    var showMapBackground: Bool {
        // Add this property to PosterDesign if not exists
        return false
    }
}