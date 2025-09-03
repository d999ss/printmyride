import UIKit
import LinkPresentation

enum ShareSheet {
    static func present(fileURL: URL, previewPNGData: Data? = nil) {
        var items: [Any] = [fileURL]
        if let data = previewPNGData, let img = UIImage(data: data) {
            items.insert(img, at: 0)
        }
        
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let win = scene.windows.first,
           let vc = win.rootViewController {
            vc.present(av, animated: true)
        }
    }
    
    static func present(items: [Any]) {
        guard !items.isEmpty else { return }
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let win = scene.windows.first, let vc = win.rootViewController {
            vc.present(av, animated: true)
        }
    }
    
    static func present(items: Any...) { present(items: items) }
    
    // Enhanced sharing with rich previews for iMessage
    static func presentRichShare(
        title: String,
        subtitle: String? = nil,
        image: UIImage?,
        url: URL? = nil,
        additionalItems: [Any] = []
    ) {
        var activityItems: [Any] = []
        
        // Create rich link metadata for iMessage
        if let url = url {
            let linkSource = RichLinkSource(title: title, subtitle: subtitle, image: image, url: url)
            activityItems.append(linkSource)
        }
        
        // Add image and text
        if let image = image {
            activityItems.append(image)
        }
        
        let shareText = subtitle != nil ? "\(title)\n\(subtitle!)" : title
        activityItems.append(shareText)
        
        // Add any additional items
        activityItems.append(contentsOf: additionalItems)
        
        let av = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Set subject for better email/message sharing
        av.setValue(title, forKey: "subject")
        
        // Present with iPad support
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let vc = window.rootViewController {
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                av.popoverPresentationController?.sourceView = window
                av.popoverPresentationController?.sourceRect = CGRect(
                    x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0
                )
                av.popoverPresentationController?.permittedArrowDirections = []
            }
            
            vc.present(av, animated: true)
        }
    }
}

// MARK: - Rich Link Preview Support

@available(iOS 13.0, *)
private class RichLinkSource: NSObject, UIActivityItemSource {
    private let title: String
    private let subtitle: String?
    private let image: UIImage?
    private let url: URL
    
    init(title: String, subtitle: String?, image: UIImage?, url: URL) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.url = url
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return url
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        metadata.title = title
        
        // Note: LPLinkMetadata doesn't have a subtitle property
        // The subtitle is handled through the title or summary instead
        if let subtitle = subtitle {
            metadata.title = "\(title) • \(subtitle)"
        }
        
        if let image = image {
            metadata.imageProvider = NSItemProvider(object: image)
        }
        
        metadata.iconProvider = NSItemProvider(object: UIImage(systemName: "bicycle") ?? UIImage())
        
        return metadata
    }
}