import SwiftUI
import Foundation
import UIKit

// MARK: - Improved Simplify Algorithm with Batch Processing

extension Simplify {
    /// Parallel point simplification using actor isolation
    static func parallelRDP(_ points: [CGPoint], epsilon: Double, minChunkSize: Int = 500) async -> [CGPoint] {
        guard points.count > minChunkSize * 2 else {
            return rdp(points, epsilon: epsilon)
        }
        
        let chunkSize = max(minChunkSize, points.count / ProcessInfo.processInfo.activeProcessorCount)
        let chunks = points.chunked(into: chunkSize)
        
        let simplifiedChunks = await withTaskGroup(of: [CGPoint].self) { group in
            for chunk in chunks {
                group.addTask {
                    return rdp(chunk, epsilon: epsilon)
                }
            }
            
            var results: [[CGPoint]] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        return simplifiedChunks.flatMap { $0 }
    }
    
    /// Memory-efficient budget with priority preservation
    static func smartBudget(_ points: [CGPoint], maxPoints: Int, preserveEnds: Bool = true) -> [CGPoint] {
        guard points.count > maxPoints else { return points }
        
        if maxPoints < 3 { return Array(points.prefix(maxPoints)) }
        
        var result: [CGPoint] = []
        
        if preserveEnds {
            result.append(points.first!)
            let step = Float(points.count - 2) / Float(maxPoints - 2)
            
            for i in 1..<(maxPoints - 1) {
                let index = Int(Float(i) * step) + 1
                result.append(points[index])
            }
            
            result.append(points.last!)
        } else {
            let step = Float(points.count) / Float(maxPoints)
            for i in 0..<maxPoints {
                let index = Int(Float(i) * step)
                result.append(points[index])
            }
        }
        
        return result
    }
}

// MARK: - Enhanced Image Cache with Memory Management

actor EnhancedImageCache {
    private var cache: [String: CacheEntry] = [:]
    private let maxMemoryMB: Int = 100
    private let maxAge: TimeInterval = 3600 // 1 hour
    
    private struct CacheEntry {
        let image: UIImage
        let timestamp: Date
        let memorySize: Int
    }
    
    func image(for key: String) -> UIImage? {
        // Clean expired entries
        await cleanupExpired()
        
        guard let entry = cache[key] else { return nil }
        return entry.image
    }
    
    func setImage(_ image: UIImage, for key: String) {
        let memorySize = estimateMemorySize(image)
        let entry = CacheEntry(image: image, timestamp: Date(), memorySize: memorySize)
        
        cache[key] = entry
        
        // Enforce memory limits
        await enforceMemoryLimits()
    }
    
    private func estimateMemorySize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4 // 4 bytes per pixel (RGBA)
    }
    
    private func cleanupExpired() {
        let now = Date()
        cache = cache.filter { now.timeIntervalSince($0.value.timestamp) < maxAge }
    }
    
    private func enforceMemoryLimits() {
        let maxBytes = maxMemoryMB * 1024 * 1024
        let currentMemory = cache.values.reduce(0) { $0 + $1.memorySize }
        
        guard currentMemory > maxBytes else { return }
        
        // Remove oldest entries
        let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        var remainingMemory = currentMemory
        
        for (key, entry) in sorted {
            guard remainingMemory > maxBytes else { break }
            cache.removeValue(forKey: key)
            remainingMemory -= entry.memorySize
        }
    }
}

// MARK: - Optimized Map Snapshot Service

class OptimizedMapSnapshotService {
    private static let cache = EnhancedImageCache()
    private static let concurrent = DispatchQueue(label: "map.snapshot", qos: .userInitiated, attributes: .concurrent)
    
    static func snapshot(coords: [CLLocationCoordinate2D], size: CGSize, priority: TaskPriority = .medium) async -> UIImage? {
        let cacheKey = generateCacheKey(coords: coords, size: size)
        
        // Check cache
        if let cached = await cache.image(for: cacheKey) {
            return cached
        }
        
        // Perform snapshot with priority
        let result = await withTaskGroup(of: UIImage?.self) { group in
            group.addTask(priority: priority) {
                await performSnapshot(coords: coords, size: size)
            }
            return await group.first { $0 != nil } ?? nil
        }
        
        // Cache result
        if let image = result {
            await cache.setImage(image, for: cacheKey)
        }
        
        return result
    }
    
    private static func performSnapshot(coords: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = MKMapSnapshotter.Options()
            options.region = RouteMapHelpers.region(fitting: coords)
            options.size = size
            options.showsBuildings = false
            options.pointOfInterestFilter = .excludingAll
            
            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.start { snapshot, error in
                continuation.resume(returning: snapshot?.image)
            }
        }
    }
    
    private static func generateCacheKey(coords: [CLLocationCoordinate2D], size: CGSize) -> String {
        let bounds = coords.boundingRect()
        return "snap_\(bounds.hashValue)_\(Int(size.width))x\(Int(size.height))"
    }
}

// MARK: - Streaming Poster Export for Large Images

actor StreamingPosterExport {
    static func exportLargePoster(design: PosterDesign, route: GPXRoute?, targetSize: CGSize, dpi: Int = 300) async -> Data? {
        let tileSize = CGSize(width: 512, height: 512)
        let tilesX = Int(ceil(targetSize.width / tileSize.width))
        let tilesY = Int(ceil(targetSize.height / tileSize.height))
        
        // Render tiles in parallel
        let tiles = await withTaskGroup(of: (Int, Int, UIImage?).self) { group in
            for x in 0..<tilesX {
                for y in 0..<tilesY {
                    group.addTask {
                        let tileRect = CGRect(
                            x: CGFloat(x) * tileSize.width,
                            y: CGFloat(y) * tileSize.height,
                            width: tileSize.width,
                            height: tileSize.height
                        )
                        let tile = await renderTile(design: design, route: route, tileRect: tileRect, targetSize: targetSize)
                        return (x, y, tile)
                    }
                }
            }
            
            var results: [(Int, Int, UIImage?)] = []
            for await tile in group {
                results.append(tile)
            }
            return results
        }
        
        // Composite tiles
        return await compositeTiles(tiles, tilesX: tilesX, tilesY: tilesY, tileSize: tileSize)
    }
    
    private static func renderTile(design: PosterDesign, route: GPXRoute?, tileRect: CGRect, targetSize: CGSize) async -> UIImage? {
        // Render a specific tile of the poster
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: tileRect.size)
                let result = renderer.image { context in
                    // Translate context for this tile
                    context.cgContext.translateBy(x: -tileRect.origin.x, y: -tileRect.origin.y)
                    
                    // Render poster content for this region
                    // (Implementation would depend on poster structure)
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    @MainActor
    private static func compositeTiles(_ tiles: [(Int, Int, UIImage?)], tilesX: Int, tilesY: Int, tileSize: CGSize) async -> Data? {
        let finalSize = CGSize(width: CGFloat(tilesX) * tileSize.width, height: CGFloat(tilesY) * tileSize.height)
        
        let renderer = UIGraphicsImageRenderer(size: finalSize)
        let composite = renderer.image { context in
            for (x, y, tile) in tiles {
                guard let tile = tile else { continue }
                let origin = CGPoint(x: CGFloat(x) * tileSize.width, y: CGFloat(y) * tileSize.height)
                tile.draw(at: origin)
            }
        }
        
        return composite.pngData()
    }
}

// MARK: - Helper Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element == CLLocationCoordinate2D {
    func boundingRect() -> MKMapRect {
        guard !isEmpty else { return MKMapRect.null }
        
        let points = map { MKMapPoint($0) }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        
        return MKMapRect(
            x: xs.min()!,
            y: ys.min()!,
            width: xs.max()! - xs.min()!,
            height: ys.max()! - ys.min()!
        )
    }
}