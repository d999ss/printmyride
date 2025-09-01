import Foundation
import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    
    private init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB memory limit
        
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = documentsPath.appendingPathComponent("ImageCache")
        
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    func image(for key: String) -> UIImage? {
        if let memoryImage = cache.object(forKey: key as NSString) {
            return memoryImage
        }
        
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
        guard let data = try? Data(contentsOf: fileURL),
              let diskImage = UIImage(data: data) else {
            return nil
        }
        
        cache.setObject(diskImage, forKey: key as NSString)
        return diskImage
    }
    
    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
        
        Task.detached(priority: .background) {
            let fileURL = self.diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
            guard let data = image.pngData() else { return }
            try? data.write(to: fileURL)
        }
    }
    
    func removeImage(for key: String) {
        cache.removeObject(forKey: key as NSString)
        
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func clearMemoryCache() {
        cache.removeAllObjects()
    }
    
    func clearDiskCache() {
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
}