import SwiftUI

enum PosterRenderMode { case editor, export }

struct PosterPreview: View {
    let design: PosterDesign
    let posterTitle: String?
    let mode: PosterRenderMode
    let route: GPXRoute?
    let payload: RoutePayload?

    @AppStorage("activePosterStyle") private var activeStyleID: String = "gallery/pyrenees"
    private var style: PosterStyle { StyleRegistry.style(id: activeStyleID) }

    var body: some View {
        switch style.layout {
        case .gallery:
            GalleryPoster(style: style,
                          title: posterTitle ?? "My Ride",
                          payload: payload!)
        case .classic:
            ClassicMapPoster(style: style,
                             title: posterTitle ?? "My Ride",
                             payload: payload!,
                             mode: mode)
        }
    }
}