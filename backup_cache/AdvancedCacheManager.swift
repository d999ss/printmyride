// PrintMyRide/Services/Cache/AdvancedCacheManager.swift
import UIKit
import os.log

/// Advanced multi-tier caching system with memory pressure handling
actor AdvancedCacheManager {
    // MARK: - Configuration
    struct Configuration {
        let memoryCapacityMB: Int
        let diskCapacityMB: Int
        let maxAge: TimeInterval
        let compressionQuality: CGFloat
        let enableDiskCache: Bool
        
        static let standard = Configuration(
            memoryCapacityMB: 150,
            diskCapacityMB: 500,
            maxAge: 3600, // 1 hour
            compressionQuality: 0.8,
            enableDiskCache: true
        )
        
        static let aggressive = Configuration(
            memoryCapacityMB: 200,
            diskCapacityMB: 1000,
            maxAge: 7200, // 2 hours
            compressionQuality: 0.9,
            enableDiskCache: true
        )
    }
    
    // MARK: - Properties
    private let configuration: Configuration
    private let logger = Logger(subsystem: "PMR", category: "AdvancedCache")
    
    // Memory cache
    private var memoryCache: [String: CacheEntry] = [:]
    private var accessOrder: [String] = []
    
    // Disk cache
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Statistics
    private var stats = CacheStatistics()
    
    // MARK: - Initialization
    init(configuration: Configuration = .standard) {
        self.configuration = configuration
        
        // Setup cache directory
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesURL.appendingPathComponent("PMRAdvancedCache")
        
        setupCacheDirectory()
        setupMemoryPressureMonitoring()
    }
    
    // MARK: - Public Interface
    func image(for key: String) async -> UIImage? {
        logger.debug("Cache lookup for key: \(key)")
        stats.totalRequests += 1
        
        // Check memory cache first
        if let entry = memoryCache[key] {
            updateAccessOrder(key)
            
            if isEntryValid(entry) {
                stats.memoryHits += 1
                logger.debug("Memory cache hit for key: \(key)")
                return entry.image
            } else {
                // Remove expired entry
                memoryCache.removeValue(forKey: key)
                removeFromAccessOrder(key)
            }
        }
        
        // Check disk cache
        if configuration.enableDiskCache {
            if let image = await loadFromDisk(key: key) {
                stats.diskHits += 1
                logger.debug("Disk cache hit for key: \(key)")
                
                // Promote to memory cache
                await setInMemoryCache(image: image, key: key)
                return image
            }
        }
        
        stats.misses += 1
        logger.debug("Cache miss for key: \(key)")
        return nil
    }
    
    func setImage(_ image: UIImage, for key: String, priority: CachePriority = .normal) async {
        logger.debug("Caching image for key: \(key) with priority: \(priority)")
        
        // Always cache in memory
        await setInMemoryCache(image: image, key: key, priority: priority)
        
        // Cache to disk if enabled and appropriate priority
        if configuration.enableDiskCache && priority != .temporary {
            await saveToDisk(image: image, key: key)
        }
    }
    
    func removeImage(for key: String) async {
        memoryCache.removeValue(forKey: key)
        removeFromAccessOrder(key)
        
        if configuration.enableDiskCache {
            await removeFromDisk(key: key)
        }
        
        logger.debug("Removed cached image for key: \(key)")
    }
    
    func clearCache() async {
        memoryCache.removeAll()
        accessOrder.removeAll()
        
        if configuration.enableDiskCache {
            await clearDiskCache()
        }
        
        stats = CacheStatistics()
        logger.info("Cache cleared")
    }
    
    func getStatistics() -> CacheStatistics {
        stats.memoryUsageMB = getCurrentMemoryUsage()
        stats.entryCount = memoryCache.count
        return stats
    }
    
    // MARK: - Memory Cache Management
    private func setInMemoryCache(image: UIImage, key: String, priority: CachePriority = .normal) async {
        let memorySize = estimateMemorySize(image)
        let entry = CacheEntry(
            image: image,
            timestamp: Date(),
            memorySize: memorySize,
            priority: priority
        )
        
        memoryCache[key] = entry
        updateAccessOrder(key)
        
        await enforceMemoryLimits()
    }
    
    private func enforceMemoryLimits() async {
        let maxBytes = configuration.memoryCapacityMB * 1024 * 1024
        var currentMemory = getCurrentMemoryUsage()
        
        guard currentMemory > maxBytes else { return }
        
        logger.info("Memory limit exceeded (\(currentMemory/1024/1024)MB > \(configuration.memoryCapacityMB)MB), evicting entries")
        
        // Sort by priority and access time (LRU within priority groups)
        let evictionOrder = memoryCache.sorted { entry1, entry2 in
            if entry1.value.priority != entry2.value.priority {
                return entry1.value.priority.rawValue < entry2.value.priority.rawValue
            }
            return entry1.value.timestamp < entry2.value.timestamp
        }
        
        for (key, entry) in evictionOrder {
            guard currentMemory > maxBytes else { break }
            
            memoryCache.removeValue(forKey: key)
            removeFromAccessOrder(key)
            currentMemory -= entry.memorySize
            
            logger.debug("Evicted entry: \(key) (\(entry.memorySize/1024/1024)MB)")
        }
        
        stats.evictions += evictionOrder.count - memoryCache.count
    }
    
    // MARK: - Disk Cache Management
    private func saveToDisk(image: UIImage, key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.hashValue).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: configuration.compressionQuality) else {
            logger.error("Failed to convert image to JPEG data for key: \(key)")
            return
        }
        
        do {
            try imageData.write(to: fileURL)
            logger.debug("Saved image to disk for key: \(key)")
        } catch {
            logger.error("Failed to save image to disk for key: \(key), error: \(error)")
        }
    }
    
    private func loadFromDisk(key: String) async -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.hashValue).jpg")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Check file age
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                if Date().timeIntervalSince(modificationDate) > configuration.maxAge {
                    try fileManager.removeItem(at: fileURL)
                    return nil
                }
            }
        } catch {
            logger.error("Failed to check file attributes for key: \(key)")
            return nil
        }
        
        // Load image
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            logger.error("Failed to load image from disk for key: \(key)")
            return nil
        }
        
        return image
    }
    
    private func removeFromDisk(key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.hashValue).jpg")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                logger.error("Failed to remove disk cache file for key: \(key)")
            }
        }
    }
    
    private func clearDiskCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            logger.info("Disk cache cleared")
        } catch {
            logger.error("Failed to clear disk cache: \(error)")
        }
    }
    
    // MARK: - Utilities
    private func setupCacheDirectory() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                logger.error("Failed to create cache directory: \(error)")
            }
        }
    }
    
    private func setupMemoryPressureMonitoring() {
        // Monitor memory pressure and proactively evict cache entries
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task {
                await self?.handleMemoryPressure()
            }
        }
    }
    
    private func handleMemoryPressure() async {
        logger.warning("Memory pressure detected, aggressively evicting cache")
        
        // Remove 50% of cache entries, starting with lowest priority
        let targetSize = memoryCache.count / 2
        let sortedEntries = memoryCache.sorted { entry1, entry2 in
            if entry1.value.priority != entry2.value.priority {
                return entry1.value.priority.rawValue < entry2.value.priority.rawValue
            }
            return entry1.value.timestamp < entry2.value.timestamp
        }
        
        for (key, _) in sortedEntries.prefix(targetSize) {
            memoryCache.removeValue(forKey: key)
            removeFromAccessOrder(key)
        }
        
        stats.pressureEvictions += targetSize
    }
    
    private func estimateMemorySize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4 // 4 bytes per pixel (RGBA)
    }
    
    private func getCurrentMemoryUsage() -> Int {
        return memoryCache.values.reduce(0) { $0 + $1.memorySize }
    }
    
    private func updateAccessOrder(_ key: String) {
        removeFromAccessOrder(key)
        accessOrder.append(key)
    }
    
    private func removeFromAccessOrder(_ key: String) {
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
    }
    
    private func isEntryValid(_ entry: CacheEntry) -> Bool {
        return Date().timeIntervalSince(entry.timestamp) < configuration.maxAge
    }
}

// MARK: - Supporting Types
enum CachePriority: Int, CaseIterable {
    case temporary = 0  // Evicted first
    case normal = 1     // Standard caching
    case high = 2       // Kept longer
    case critical = 3   // Evicted last
}

struct CacheEntry {
    let image: UIImage
    let timestamp: Date
    let memorySize: Int
    let priority: CachePriority
}

struct CacheStatistics {
    var totalRequests: Int = 0
    var memoryHits: Int = 0
    var diskHits: Int = 0
    var misses: Int = 0
    var evictions: Int = 0
    var pressureEvictions: Int = 0
    var memoryUsageMB: Int = 0
    var entryCount: Int = 0
    
    var hitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHits + diskHits) / Double(totalRequests)
    }
    
    var memoryHitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHits) / Double(totalRequests)
    }
}

// MARK: - Global Cache Instance
extension AdvancedCacheManager {
    static let shared = AdvancedCacheManager()
    
    /// Convenience method for global access
    static func image(for key: String) async -> UIImage? {
        await shared.image(for: key)
    }
    
    static func setImage(_ image: UIImage, for key: String, priority: CachePriority = .normal) async {
        await shared.setImage(image, for: key, priority: priority)
    }
}