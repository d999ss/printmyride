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
    @AppStorage("useOptimizedRenderer") private var useOptimizedRenderer = true

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

    private func generate() async -> UIImage? {
        print("🎨 generate() fallback for '\(posterTitle)' with \(coords.count) coords")
        
        // Render a route thumbnail; if coords are empty, render a neutral poster tile
        if !coords.isEmpty {
            let lineWidth = max(6, min(12, thumbSize.width * 0.02)) // Thicker line for better visibility
            print("🎨 Calling RouteRenderer.renderImage with lineWidth: \(lineWidth)")
            
            let result = await RouteRenderer.renderImage(
                from: coords,
                size: thumbSize,
                lineWidth: lineWidth
            )
            
            if let image = result {
                print("✅ RouteRenderer returned image: \(Int(image.size.width))x\(Int(image.size.height))")
            } else {
                print("❌ RouteRenderer returned nil for '\(posterTitle)'")
            }
            
            return result
        } else {
            print("⚠️ No coordinates for '\(posterTitle)', generating neutral tile")
            
            // Enhanced neutral background tile with better visibility
            let renderer = UIGraphicsImageRenderer(size: thumbSize)
            return renderer.image { ctx in
                // Black background
                UIColor.black.setFill()
                ctx.fill(CGRect(origin: .zero, size: thumbSize))
                
                // White border for contrast
                let borderRect = CGRect(x: 8, y: 8, width: thumbSize.width-16, height: thumbSize.height-16)
                let path = UIBezierPath(roundedRect: borderRect, cornerRadius: 8)
                UIColor.white.withAlphaComponent(0.2).setStroke()
                path.lineWidth = 2
                path.stroke()
                
                // Center text indicator
                let text = "No Route"
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.white.withAlphaComponent(0.4),
                    .font: UIFont.systemFont(ofSize: min(thumbSize.width/10, 12))
                ]
                let textSize = text.size(withAttributes: attrs)
                let textRect = CGRect(
                    x: (thumbSize.width - textSize.width) / 2,
                    y: (thumbSize.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                text.draw(in: textRect, withAttributes: attrs)
            }
        }
    }

    private func loadOrGenerate() async {
        print("🎨 PosterThumbProvider: Starting loadOrGenerate for '\(posterTitle)'")
        print("🎨 Coords count: \(coords.count), ThumbPath: \(thumbPath)")
        
        // 1) Try disk
        if let ui = loadDisk() {
            print("✅ Loaded from disk: \(posterTitle)")
            await MainActor.run { self.image = ui }
            return
        }
        
        // 2) Try optimized renderer first if enabled
        if useOptimizedRenderer && !coords.isEmpty {
            print("⚡ Trying optimized renderer for: \(posterTitle)")
            if let optimizedImage = await generateOptimized() {
                write(optimizedImage)
                await MainActor.run { self.image = optimizedImage }
                print("✅ Generated with optimized renderer: \(posterTitle)")
                return
            }
            print("⚠️ Optimized renderer failed for: \(posterTitle)")
        }
        
        // 3) Try Apple Maps snapshot (if we have coords)
        if !coords.isEmpty, let snap = await snapshotImage(coords: coords, size: thumbSize) {
            write(snap)
            await MainActor.run { self.image = snap }
            print("✅ Generated with Maps snapshot: \(posterTitle)")
            return
        }
        
        // 4) Fallback: offline route render
        if let ui = await generate() {
            write(ui)
            await MainActor.run { self.image = ui }
            print("✅ Generated with fallback render: \(posterTitle)")
        } else {
            print("❌ All generation methods failed for: \(posterTitle)")
        }
    }

    // MARK: - Optimized Generation
    
    private func generateOptimized() async -> UIImage? {
        print("🎨 generateOptimized for '\(posterTitle)' with \(coords.count) coords")
        
        // Create a basic poster design for thumbnails
        let design = createThumbnailDesign()
        let points = coords.map { GPXRoute.Point(lat: $0.latitude, lon: $0.longitude) }
        let route = GPXRoute(points: points, distanceMeters: 0, duration: nil)
        
        print("🎨 Calling PosterRenderService.shared.renderPoster...")
        let result = await PosterRenderService.shared.renderPoster(
            design: design,
            route: route,
            size: thumbSize,
            quality: .preview
        )
        
        if let image = result {
            print("✅ PosterRenderService returned image: \(Int(image.size.width))x\(Int(image.size.height))")
        } else {
            print("❌ PosterRenderService returned nil for '\(posterTitle)'")
        }
        
        return result
    }
    
    private func createThumbnailDesign() -> PosterDesign {
        var design = PosterDesign()
        design.paperSize = CGSize(width: thumbSize.width/72, height: thumbSize.height/72) // Convert pixels to inches
        design.backgroundColor = .clear // Clear background to show map
        design.routeColor = Color(UIColor.systemBrown) // Brown route line for visibility on map
        design.strokeWidthPt = max(6.0, thumbSize.width * 0.02) // Thicker stroke for visibility in thumbnails
        design.margins = 0.10 // 10% margins so route fills more of the frame
        design.lineCap = .round // Smooth line endings
        
        print("🎨 Thumbnail design: \(Int(thumbSize.width))x\(Int(thumbSize.height))px, stroke: \(design.strokeWidthPt)pt, margins: \(design.margins)")
        
        return design
    }

    private func snapshotImage(coords: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        await withCheckedContinuation { cont in
            MapSnapshotService.snapshot(coords: coords, size: size) { img in
                cont.resume(returning: img)
            }
        }
    }
}