import UIKit

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
}