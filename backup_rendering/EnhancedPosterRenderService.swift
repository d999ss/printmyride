// PrintMyRide/Services/Rendering/EnhancedPosterRenderService.swift
import UIKit
import MapKit
import os.log

protocol EnhancedPosterRenderServiceProtocol {
    func renderPoster(request: PosterRenderRequest) async throws -> UIImage
}

struct EnhancedPosterRenderServiceFactory {
    static func create() -> EnhancedPosterRenderServiceProtocol {
        if ProcessInfo.processInfo.environment["USE_OPTIMIZED_RENDERER"] == "true" {
            return OptimizedEnhancedPosterRenderService()
        } else {
            return StandardEnhancedPosterRenderService()
        }
    }
}

// MARK: - Optimized Service (uses existing performance improvements)
final class OptimizedEnhancedPosterRenderService: EnhancedPosterRenderServiceProtocol {
    private let logger = Logger(subsystem: "PMR", category: "EnhancedRenderer")
    private let cache = PosterImageCache()
    
    func renderPoster(request: PosterRenderRequest) async throws -> UIImage {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check cache first
        let cacheKey = generateCacheKey(from: request)
        if let cached = await cache.image(for: cacheKey) {
            logger.info("Cache hit for render request")
            return cached
        }
        
        logger.info("Starting enhanced render pipeline")
        
        // Try optimized renderer first
        if request.useOptimizedRenderer,
           let optimizedImage = await tryOptimizedRender(request) {
            await cache.setImage(optimizedImage, for: cacheKey)
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            logger.info("Optimized render completed: \(duration, format: .fixed(precision: 1))ms")
            return optimizedImage
        }
        
        // Fallback to enhanced composite rendering
        let fallbackImage = try await enhancedFallbackRender(request)
        await cache.setImage(fallbackImage, for: cacheKey)
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        logger.info("Fallback render completed: \(duration, format: .fixed(precision: 1))ms")
        
        return fallbackImage
    }
    
    private func tryOptimizedRender(_ request: PosterRenderRequest) async -> UIImage? {
        // This would integrate with your existing optimized renderer
        // For now, return nil to use fallback
        return nil
    }
    
    private func enhancedFallbackRender(_ request: PosterRenderRequest) async throws -> UIImage {
        let coords = request.rideData.coordinates
        guard !coords.isEmpty else {
            throw PosterRenderError.noCoordinates
        }
        
        // Parallel rendering pipeline
        async let mapTask = renderMapBackground(request)
        async let routeTask = renderRouteOverlay(request)
        
        let (mapImage, routeImage) = await (mapTask, routeTask)
        
        // Composite final image
        return await compositeLayers(
            background: request.preset.backgroundColor,
            mapImage: mapImage,
            routeImage: routeImage,
            request: request
        )
    }
    
    private func renderMapBackground(_ request: PosterRenderRequest) async -> UIImage? {
        guard request.useMapBackground else { return nil }
        
        return await MapSnapshotService.pmrSnapshotKnownGood(
            coords: request.rideData.coordinates,
            size: request.canvasSize,
            style: request.mapStyle
        )
    }
    
    private func renderRouteOverlay(_ request: PosterRenderRequest) async -> UIImage? {
        return await LegacyRendererBridge.renderImage(
            coords: request.rideData.coordinates,
            size: request.canvasSize,
            background: .clear,
            routeColor: UIColor(request.preset.routeColor),
            stroke: max(6, request.canvasSize.width * 0.008),
            title: request.rideData.title,
            stats: formatStatsLines(request.rideData)
        )
    }
    
    @MainActor
    private func compositeLayers(
        background: Color,
        mapImage: UIImage?,
        routeImage: UIImage?,
        request: PosterRenderRequest
    ) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: request.canvasSize)
        
        return renderer.image { context in
            // Background
            UIColor(background).setFill()
            context.fill(CGRect(origin: .zero, size: request.canvasSize))
            
            // Map layer
            if let mapImage = mapImage {
                mapImage.draw(at: .zero)
            }
            
            // Route layer
            if let routeImage = routeImage {
                routeImage.draw(at: .zero)
            }
        }
    }
    
    private func generateCacheKey(from request: PosterRenderRequest) -> String {
        let coords = request.rideData.coordinates
        let bounds = coords.isEmpty ? "empty" : "\(coords.boundingRect().hashValue)"
        return "enhanced_poster_\(bounds)_\(request.preset.hashValue)_\(Int(request.canvasSize.width))x\(Int(request.canvasSize.height))_\(request.useMapBackground)_\(request.mapStyle)"
    }
    
    private func formatStatsLines(_ rideData: RideData) -> [String] {
        let miles = rideData.distanceMeters / 1609.344
        let feet = rideData.elevationMeters * 3.28084
        let duration = formatDuration(rideData.durationSeconds)
        let dateStr = rideData.date.formatted(date: .abbreviated, time: .omitted)
        
        return [
            "Distance  \(String(format: "%.1f mi", miles))",
            "Climb     \(Int(feet)) ft",
            "Time      \(duration)  •  \(dateStr)"
        ]
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Standard Service (simplified)
final class StandardEnhancedPosterRenderService: EnhancedPosterRenderServiceProtocol {
    func renderPoster(request: PosterRenderRequest) async throws -> UIImage {
        guard let image = await LegacyRendererBridge.renderImage(
            coords: request.rideData.coordinates,
            size: request.canvasSize,
            background: UIColor(request.preset.backgroundColor),
            routeColor: UIColor(request.preset.routeColor),
            stroke: max(6, request.canvasSize.width * 0.008),
            title: request.rideData.title,
            stats: formatStatsLines(request.rideData)
        ) else {
            throw PosterRenderError.renderFailed
        }
        
        return image
    }
    
    private func formatStatsLines(_ rideData: RideData) -> [String] {
        let miles = rideData.distanceMeters / 1609.344
        let feet = rideData.elevationMeters * 3.28084
        let duration = formatDuration(rideData.durationSeconds)
        let dateStr = rideData.date.formatted(date: .abbreviated, time: .omitted)
        
        return [
            "Distance  \(String(format: "%.1f mi", miles))",
            "Climb     \(Int(feet)) ft",
            "Time      \(duration)  •  \(dateStr)"
        ]
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Errors
enum PosterRenderError: LocalizedError {
    case noCoordinates
    case renderFailed
    case invalidRequest
    
    var errorDescription: String? {
        switch self {
        case .noCoordinates:
            return "No route coordinates available"
        case .renderFailed:
            return "Poster rendering failed"
        case .invalidRequest:
            return "Invalid render request"
        }
    }
}

// MARK: - Image Cache
actor PosterImageCache {
    private var cache: [String: CacheEntry] = [:]
    private let maxMemoryMB: Int = 150
    private let maxAge: TimeInterval = 3600 // 1 hour
    
    private struct CacheEntry {
        let image: UIImage
        let timestamp: Date
        let memorySize: Int
    }
    
    func image(for key: String) -> UIImage? {
        cleanupExpired()
        return cache[key]?.image
    }
    
    func setImage(_ image: UIImage, for key: String) {
        let memorySize = estimateMemorySize(image)
        let entry = CacheEntry(image: image, timestamp: Date(), memorySize: memorySize)
        
        cache[key] = entry
        enforceMemoryLimits()
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

// MARK: - Extensions
extension Array where Element == CLLocationCoordinate2D {
    func boundingRect() -> MKMapRect {
        guard !isEmpty else { return MKMapRect.null }
        
        let points = map { MKMapPoint($0) }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else {
            return MKMapRect.null
        }
        
        return MKMapRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
}