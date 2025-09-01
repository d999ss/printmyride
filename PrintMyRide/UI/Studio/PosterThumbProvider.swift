import SwiftUI
import CoreLocation
import MapKit

/// Loads a poster thumbnail from Documents. If missing, tries Apple Maps snapshot
/// with route overlay, else falls back to local route render. Guarantees a non-blank image.
struct PosterThumbProvider: View {
    let thumbPath: String
    let posterTitle: String
    let coords: [CLLocationCoordinate2D]
    let thumbSize: CGSize

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color.gray.opacity(0.12)
                    .task { await loadOrGenerate() }
            }
        }
    }

    private func loadURL() -> URL {
        documentsURL().appendingPathComponent(thumbPath).standardizedFileURL
    }

    private func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func loadDisk() -> UIImage? {
        let url = loadURL()
        if let data = try? Data(contentsOf: url), let ui = UIImage(data: data) { return ui }
        // Fallback for any odd URL issue
        if let ui = UIImage(contentsOfFile: url.path) { return ui }
        return nil
    }

    private func write(_ ui: UIImage) {
        guard let data = ui.jpegData(compressionQuality: 0.9) else { return }
        let url = loadURL()
        try? data.write(to: url, options: .atomic)
    }

    private func generate() -> UIImage? {
        // Render a route thumbnail; if coords are empty, render a neutral poster tile
        if !coords.isEmpty {
            return RouteRenderer.renderImage(
                from: coords,
                size: thumbSize,
                lineWidth: max(4, min(10, thumbSize.width * 0.01))
            )
        } else {
            // simple neutral background tile
            let renderer = UIGraphicsImageRenderer(size: thumbSize)
            return renderer.image { ctx in
                UIColor.black.setFill()
                ctx.fill(CGRect(origin: .zero, size: thumbSize))
                let path = UIBezierPath(roundedRect: CGRect(x: 16, y: 16, width: thumbSize.width-32, height: thumbSize.height-32), cornerRadius: 12)
                UIColor(white: 1, alpha: 0.04).setStroke()
                path.lineWidth = 2
                path.stroke()
            }
        }
    }

    private func loadOrGenerate() async {
        // 1) Try disk
        if let ui = loadDisk() {
            await MainActor.run { self.image = ui }
            return
        }
        
        // 2) Try Apple Maps snapshot (if we have coords)
        if !coords.isEmpty, let snap = await snapshotImage(coords: coords, size: thumbSize) {
            write(snap)
            await MainActor.run { self.image = snap }
            return
        }
        
        // 3) Fallback: offline route render
        if let ui = generate() {
            write(ui)
            await MainActor.run { self.image = ui }
        }
    }

    private func snapshotImage(coords: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        await withCheckedContinuation { cont in
            MapSnapshotService.snapshot(coords: coords, size: size) { img in
                cont.resume(returning: img)
            }
        }
    }
}