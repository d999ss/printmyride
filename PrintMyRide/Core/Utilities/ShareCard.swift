import SwiftUI

enum ShareCard {
    @MainActor
    static func generate(design: PosterDesign, route: GPXRoute?, title: String, size: CGFloat = 1024) -> Data? {
        let inset = size * 0.08
        let view = ZStack {
            Color(.black)
            VStack(spacing: size * 0.04) {
                PosterPreview(design: design, posterTitle: title.isEmpty ? "My Ride" : title, mode: .export, route: route, payload: nil)
                    .frame(width: size - inset * 2, height: size * 0.72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(title.isEmpty ? "My Ride" : title)
                    .font(.system(size: size * 0.06, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(inset)
        }
        .frame(width: size, height: size)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        
        #if canImport(UIKit)
        return renderer.uiImage?.pngData()
        #else
        return nil
        #endif
    }
}