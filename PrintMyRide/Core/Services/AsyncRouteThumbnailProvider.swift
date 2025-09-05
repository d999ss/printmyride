import UIKit
import CoreLocation
import os.log

/// Actor-based thumbnail provider with memory and disk caching
/// Never blocks main thread or list scrolling
actor AsyncRouteThumbnailProvider {
    static let shared = AsyncRouteThumbnailProvider()
    
    private let logger = Logger(subsystem: "PMR", category: "RouteThumbnails")
    private let memoryCache = NSCache<NSString, UIImage>()
    private let cacheDirectory: URL
    
    private init() {
        // Setup memory cache
        memoryCache.countLimit = 50
        memoryCache.totalCostLimit = 25 * 1024 * 1024 // 25MB
        
        // Setup disk cache directory
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("RouteThumbnails", isDirectory: true)
        
        Task {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func thumbnail(for coordinates: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        let cacheKey = generateCacheKey(coordinates: coordinates, size: size)
        
        // 1. Check memory cache
        if let cached = memoryCache.object(forKey: cacheKey as NSString) {
            logger.debug("Memory cache hit: \(cacheKey)")
            return cached
        }
        
        // 2. Check disk cache
        if let diskCached = await loadFromDisk(key: cacheKey) {
            logger.debug("Disk cache hit: \(cacheKey)")
            memoryCache.setObject(diskCached, forKey: cacheKey as NSString)
            return diskCached
        }
        
        // 3. Generate thumbnail off main thread
        logger.debug("Generating thumbnail: \(cacheKey)")
        guard let thumbnail = await generateThumbnail(coordinates: coordinates, size: size) else {
            return nil
        }
        
        // 4. Cache the result
        memoryCache.setObject(thumbnail, forKey: cacheKey as NSString)
        await saveToDisk(image: thumbnail, key: cacheKey)
        
        return thumbnail
    }
    
    private func generateThumbnail(coordinates: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            Task.detached {
                let thumbnail = RouteThumbnailRenderer.render(
                    coordinates: coordinates,
                    size: size
                )
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func loadFromDisk(key: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            Task.detached {
                let url = self.cacheDirectory.appendingPathComponent("\(key).png")
                guard FileManager.default.fileExists(atPath: url.path),
                      let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }
    
    private func saveToDisk(image: UIImage, key: String) async {
        await withCheckedContinuation { continuation in
            Task.detached {
                let url = self.cacheDirectory.appendingPathComponent("\(key).png")
                guard let data = image.pngData() else {
                    continuation.resume()
                    return
                }
                
                try? data.write(to: url, options: .atomic)
                continuation.resume()
            }
        }
    }
    
    private func generateCacheKey(coordinates: [CLLocationCoordinate2D], size: CGSize) -> String {
        // Create a stable hash from first/last coordinates and size
        guard let first = coordinates.first,
              let last = coordinates.last else {
            return "empty_\(Int(size.width))x\(Int(size.height))"
        }
        
        let hash = "\(Int(first.latitude * 1000))_\(Int(first.longitude * 1000))_\(Int(last.latitude * 1000))_\(Int(last.longitude * 1000))_\(coordinates.count)_\(Int(size.width))x\(Int(size.height))"
        return hash
    }
    
    func clearCache() async {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

// MARK: - Route Thumbnail Renderer (Background Thread)
enum RouteThumbnailRenderer {
    static func render(coordinates: [CLLocationCoordinate2D], size: CGSize) -> UIImage? {
        guard coordinates.count > 1 else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Background
            ctx.setFillColor(UIColor.systemFill.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Normalize coordinates
            let lats = coordinates.map(\.latitude)
            let lons = coordinates.map(\.longitude)
            
            guard let minLat = lats.min(),
                  let maxLat = lats.max(),
                  let minLon = lons.min(),
                  let maxLon = lons.max() else { return }
            
            let latRange = maxLat - minLat
            let lonRange = maxLon - minLon
            
            // Handle single point or very small routes
            let effectiveLatRange = max(latRange, 0.001)
            let effectiveLonRange = max(lonRange, 0.001)
            
            // Convert to screen points with padding
            let padding: CGFloat = 4
            let availableWidth = size.width - (padding * 2)
            let availableHeight = size.height - (padding * 2)
            
            let points = coordinates.map { coord in
                let normalizedLat = (coord.latitude - minLat) / effectiveLatRange
                let normalizedLon = (coord.longitude - minLon) / effectiveLonRange
                
                return CGPoint(
                    x: padding + normalizedLon * availableWidth,
                    y: padding + (1.0 - normalizedLat) * availableHeight
                )
            }
            
            // Draw route line
            ctx.setStrokeColor(UIColor.systemBrown.cgColor)
            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            
            ctx.beginPath()
            ctx.move(to: points[0])
            for point in points.dropFirst() {
                ctx.addLine(to: point)
            }
            ctx.strokePath()
            
            // Draw start point (small green dot)
            ctx.setFillColor(UIColor.systemGreen.cgColor)
            let startDot = CGRect(x: points[0].x - 1.5, y: points[0].y - 1.5, width: 3, height: 3)
            ctx.fillEllipse(in: startDot)
        }
    }
}