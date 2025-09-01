import SwiftUI
import UIKit
import CoreLocation

struct PosterStoreWrapper {
    let store: PosterStore
    
    func savePosterFromImages(title: String, full: UIImage?, thumb: UIImage?, coordinates: [CLLocationCoordinate2D]? = nil) async throws {
        guard let full = full, let thumb = thumb else { throw PosterError.renderFailed }
        
        let uuid = UUID()
        let fullPath = "\(uuid.uuidString)_full.png"
        let thumbPath = "\(uuid.uuidString)_thumb.png"
        
        // Cache images in memory/disk cache
        let fullCacheKey = "poster_full_\(uuid.uuidString)"
        let thumbCacheKey = "poster_thumb_\(uuid.uuidString)"
        
        ImageCache.shared.setImage(full, for: fullCacheKey)
        ImageCache.shared.setImage(thumb, for: thumbCacheKey)
        
        // Save to documents directory in background
        await withTaskGroup(of: Void.self) { group in
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            group.addTask {
                if let fullData = full.pngData() {
                    try? fullData.write(to: docs.appendingPathComponent(fullPath))
                }
            }
            
            group.addTask {
                if let thumbData = thumb.pngData() {
                    try? thumbData.write(to: docs.appendingPathComponent(thumbPath))
                }
            }
        }
        
        // Create poster record
        var poster = Poster(
            id: uuid,
            title: title,
            createdAt: Date(),
            thumbnailPath: thumbPath,
            filePath: fullPath,
            coordinateData: nil
        )
        poster.coordinates = coordinates
        
        await MainActor.run {
            store.add(poster)
        }
    }
}

enum PosterError: Error {
    case renderFailed
}