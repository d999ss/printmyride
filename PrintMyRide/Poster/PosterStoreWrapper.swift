import SwiftUI
import UIKit

struct PosterStoreWrapper {
    let store: PosterStore
    
    func savePosterFromImages(title: String, full: UIImage?, thumb: UIImage?) async throws {
        guard let full = full, let thumb = thumb else { throw PosterError.renderFailed }
        
        let uuid = UUID()
        let fullPath = "\(uuid.uuidString)_full.png"
        let thumbPath = "\(uuid.uuidString)_thumb.png"
        
        // Save images to documents
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        if let fullData = full.pngData() {
            try fullData.write(to: docs.appendingPathComponent(fullPath))
        }
        if let thumbData = thumb.pngData() {
            try thumbData.write(to: docs.appendingPathComponent(thumbPath))
        }
        
        // Create poster record
        let poster = Poster(
            id: uuid,
            title: title,
            createdAt: Date(),
            thumbnailPath: thumbPath,
            filePath: fullPath
        )
        
        await MainActor.run {
            store.add(poster)
        }
    }
}

enum PosterError: Error {
    case renderFailed
}