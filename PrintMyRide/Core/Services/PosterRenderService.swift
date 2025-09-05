import SwiftUI
import UIKit
import MapKit
import os.log

/// High-performance poster renderer with aggressive optimizations
actor PosterRenderService {
    private static let logger = Logger(subsystem: "PMR", category: "PosterRender")
    private var renderCache: [String: CacheEntry] = [:]
    private let maxCacheSize = 50
    
    static let shared = PosterRenderService()
    
    private struct CacheEntry {
        let image: UIImage
        let timestamp: Date
        let memorySize: Int
    }
    
    // MARK: - Public API
    
    func renderPoster(design: PosterDesign, route: GPXRoute?, size: CGSize, quality: RenderQuality = .standard) async -> UIImage? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate cache key
        let cacheKey = generateCacheKey(design: design, route: route, size: size, quality: quality)
        
        // Check cache first
        if let cached = getCachedImage(for: cacheKey) {
            Self.logger.info("Cache hit for poster render: \((CFAbsoluteTimeGetCurrent() - startTime) * 1000)ms")
            return cached
        }
        
        Self.logger.info("Starting poster render pipeline")
        
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
            cacheResult(result, for: cacheKey)
        }
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        Self.logger.info("Poster render completed: \(String(format: "%.1f", duration))ms")
        
        return result
    }
    
    // MARK: - Optimized Map Snapshots
    
    private func renderMapSnapshot(coords: [CLLocationCoordinate2D], size: CGSize, quality: RenderQuality) async -> UIImage? {
        guard !coords.isEmpty else { 
            print("🗺️ No coordinates for map snapshot")
            return nil 
        }
        
        // Use lower resolution for previews
        let actualSize = quality == .preview ? 
            CGSize(width: size.width * 0.5, height: size.height * 0.5) : size
        
        print("🗺️ Requesting map snapshot: \(Int(actualSize.width))x\(Int(actualSize.height)), \(coords.count) coords")
        
        let result = await MapSnapshotper.snapshot(
            coords: coords,
            size: actualSize,
            scale: quality.scale,
            style: .standard
        )
        
        if let snapshot = result {
            print("✅ Map snapshot generated: \(Int(snapshot.size.width))x\(Int(snapshot.size.height))")
        } else {
            print("❌ Map snapshot failed")
        }
        
        return result
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
        let _ = RouteRegion.region(for: coords, padding: 0.1)
        let lat0 = coords.reduce(0.0, { $0 + $1.latitude }) / Double(coords.count)
        let kx = cos(lat0 * .pi/180)
        let minLat = coords.map(\.latitude).min()!
        let minLon = coords.map(\.longitude).min()!
        
        var points = coords.map { c in
            CGPoint(x: (c.longitude - minLon) * kx,
                    y: (c.latitude  - minLat))
        }
        
        // Aggressive simplification for large routes
        let targetPoints = min(2000, coords.count)
        if points.count > targetPoints {
            let viewDiag = hypot(size.width, size.height)
            points = Simplify.rdp(points, epsilon: viewDiag * 0.001)
            points = Simplify.budget(points, maxPoints: targetPoints)
        }
        
        // Scale to canvas
        let bbox = points.boundingBox()
        let contentRect = RenderMath.contentRect(in: size, margins: design.margins)
        let transform = CGAffineTransform.scaling(from: bbox, to: contentRect)
        
        points = points.map { $0.applying(transform) }
        
        // Draw with optimized path
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        ctx.setStrokeColor(UIColor(design.routeColor).cgColor)
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
        
        print("🎨 Compositing poster: map=\(mapSnapshot != nil), route=\(routePath != nil)")
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // If we have a map snapshot, use it as the background
            if let snapshot = mapSnapshot {
                // Draw map as the background
                print("🗺️ Drawing map background: \(Int(snapshot.size.width))x\(Int(snapshot.size.height))")
                ctx.draw(snapshot.cgImage!, in: CGRect(origin: .zero, size: size))
            } else {
                // Only fill with background color if no map
                print("🎨 No map - using background color: \(background)")
                ctx.setFillColor(UIColor(background).cgColor)
                ctx.fill(CGRect(origin: .zero, size: size))
            }
            
            // Route overlay
            if let route = routePath {
                print("🛤️ Drawing route overlay: \(Int(route.size.width))x\(Int(route.size.height))")
                ctx.draw(route.cgImage!, in: CGRect(origin: .zero, size: size))
            }
        }
    }
    
    // MARK: - Cache Management
    
    private func getCachedImage(for key: String) -> UIImage? {
        cleanupExpired()
        return renderCache[key]?.image
    }
    
    private func cacheResult(_ image: UIImage, for key: String) {
        let memorySize = estimateMemorySize(image)
        let entry = CacheEntry(image: image, timestamp: Date(), memorySize: memorySize)
        
        renderCache[key] = entry
        
        // LRU eviction
        if renderCache.count > maxCacheSize {
            let oldestKey = renderCache.keys.sorted { 
                renderCache[$0]!.timestamp < renderCache[$1]!.timestamp 
            }.first!
            renderCache.removeValue(forKey: oldestKey)
        }
    }
    
    private func estimateMemorySize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4 // 4 bytes per pixel (RGBA)
    }
    
    private func cleanupExpired() {
        let maxAge: TimeInterval = 3600 // 1 hour
        let now = Date()
        renderCache = renderCache.filter { now.timeIntervalSince($0.value.timestamp) < maxAge }
    }
    
    private func generateCacheKey(design: PosterDesign, route: GPXRoute?, size: CGSize, quality: RenderQuality) -> String {
        let routeHash = route?.coordinates.prefix(10).map { "\(Int($0.latitude*1000)),\(Int($0.longitude*1000))" }.joined(separator: "_") ?? "no-route"
        let designHash = "\(design.backgroundColor.hashValue)_\(design.strokeWidthPt)_\(design.routeColor.hashValue)"
        return "\(designHash)_\(routeHash)_\(Int(size.width))x\(Int(size.height))_\(quality.rawValue)"
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

// MARK: - Extensions

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