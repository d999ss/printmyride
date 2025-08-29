import SwiftUI

enum Snapshotter {
    @MainActor
    static func posterPNG(design: PosterDesign, route: GPXRoute?, size: CGSize = .init(width: 600, height: 800)) -> Data? {
        let v = PosterPreview(design: design, route: route, mode: .export)
            .frame(width: size.width, height: size.height)
            .background(design.backgroundColor.color)
        let r = ImageRenderer(content: v)
        r.scale = 2
        return r.uiImage?.pngData()
    }
    
    @MainActor
    static func posterThumb(design: PosterDesign, route: GPXRoute?,
                            size: CGSize = .init(width: 600, height: 800)) -> UIImage? {
        // Create a clean poster design for thumbnail (no HUD, no extras)
        var cleanDesign = design
        cleanDesign.showGrid = false
        
        let v = ZStack {
            Rectangle().fill(cleanDesign.backgroundColor.color)
            if let r = route {
                CanvasView(design: cleanDesign, route: r)
            }
        }
        .frame(width: size.width, height: size.height)
        
        let r = ImageRenderer(content: v)
        r.scale = 1
        #if canImport(UIKit)
        return r.uiImage
        #else
        return nil
        #endif
    }
}