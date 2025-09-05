import UIKit
import Photos

@MainActor
final class PosterExportService: ObservableObject {
    static let shared = PosterExportService()
    
    private init() {}
    
    func saveToPhotos(_ poster: Poster) {
        guard let image = loadPosterImage(poster) else { return }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        NotificationCenter.default.post(name: .posterSaved, object: nil)
                    }
                }
            }
        }
    }
    
    private func loadPosterImage(_ poster: Poster) -> UIImage? {
        // Load from cache or regenerate
        let cachedPath = poster.thumbnailPath
        if let url = URL(string: cachedPath),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        
        // Fallback: generate placeholder
        return createPlaceholderImage(title: poster.title)
    }
    
    private func createPlaceholderImage(title: String) -> UIImage {
        let size = CGSize(width: 800, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.systemBrown.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let titleString = NSAttributedString(string: title, attributes: titleAttrs)
            let titleSize = titleString.size()
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: size.height / 2 - titleSize.height / 2,
                width: titleSize.width,
                height: titleSize.height
            )
            titleString.draw(in: titleRect)
        }
    }
}

extension Notification.Name {
    static let posterSaved = Notification.Name("posterSaved")
}