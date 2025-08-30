import Foundation

enum StyleRegistry {
    static let classicModern = PosterStyle(
        id: "classic/modern",
        name: "Classic",
        layout: .classic,
        margins: .init(sidePct: 0.10, vPct: 0.03, minSide: 24, maxSide: 44, minV: 16, maxV: 28),
        map: .init(terrain: "muted", muteOpacity: 0.08, hideWatermark: true),
        route: .init(
            colorHex: "#FC4C02",
            widthRel: 0.006,
            ticks: .init(enabled: true, spacingRel: 0.016, size: 5, opacity: 0.55),
            start: .filled, finish: .ring),
        typography: .init(titleSize: 20, titleWeight: "semibold", captionSize: 12),
        caption: nil,
        footer: .init(enabled: true, paddingH: 26, paddingV: 12),
        colors: .init(paper: "#FFFFFF", panel: "#FFFFFF", title: "#000000", caption: "rgba(0,0,0,0.8)")
    )

    static let galleryPyrenees = PosterStyle(
        id: "gallery/pyrenees",
        name: "Gallery",
        layout: .gallery,
        margins: .init(sidePct: 0.10, vPct: 0.03, minSide: 36, maxSide: 72, minV: 18, maxV: 36),
        map: .init(terrain: "standard", muteOpacity: 0.08, hideWatermark: true),
        route: .init(
            colorHex:"#FC4C02",
            widthRel: 0.006,
            ticks: .init(enabled: true, spacingRel: 0.016, size: 5, opacity: 0.55),
            start: .filled, finish: .ring),
        typography: .init(titleSize: 28, titleWeight: "semibold", captionSize: 12),
        caption: .init(tokens:["distance","elevation","days","weather"],
                       bullet:"•", maxWidthPct: 0.82, gapToTitle: 4, bottomSpacePct: 0.08),
        footer: nil,
        colors: .init(paper: "#FFFFFF", panel: "#FFFFFF", title: "#000000", caption: "rgba(0,0,0,0.8)")
    )

    static let galleryGreen = PosterStyle(
        id: "gallery/green",
        name: "Gallery – Green",
        layout: .gallery,
        margins: .init(sidePct: 0.10, vPct: 0.03, minSide: 36, maxSide: 72, minV: 18, maxV: 36),
        map: .init(terrain: "standard", muteOpacity: 0.08, hideWatermark: true),
        route: .init(colorHex:"#FC4C02",
                     widthRel:0.006,
                     ticks:.init(enabled:true, spacingRel:0.016, size:5, opacity:0.55),
                     start:.filled, finish:.ring),
        typography: .init(titleSize: 28, titleWeight: "semibold", captionSize: 12),
        caption: .init(tokens:["distance","elevation","days","weather"],
                       bullet:"•", maxWidthPct: 0.82, gapToTitle: 4, bottomSpacePct: 0.08),
        footer: nil,
        colors: .init(paper:"#FFFFFF", panel:"#FFFFFF", title:"#000000", caption:"rgba(0,0,0,0.8)")
    )

    static let galleryMarmotte = PosterStyle(
        id: "gallery/marmotte-dark",
        name: "Gallery – Marmotte (Dark)",
        layout: .gallery,
        margins: .init(sidePct:0.10, vPct:0.03, minSide:36, maxSide:72, minV:18, maxV:36),
        map: .init(terrain:"standard", muteOpacity:0.50, hideWatermark:true),  // darker overlay
        route: .init(colorHex:"#FC4C02",
                     widthRel:0.006,
                     ticks:.init(enabled:true, spacingRel:0.018, size:5, opacity:0.55),
                     start:.filled, finish:.ring),
        typography: .init(titleSize:28, titleWeight:"semibold", captionSize:12),
        caption: .init(tokens:["distance","elevation","days","weather"],
                       bullet:"•", maxWidthPct:0.78, gapToTitle:4, bottomSpacePct:0.10),
        footer: nil,
        // white paper mat, dark inner panel & light text
        colors: .init(paper:"#FFFFFF", panel:"#121212", title:"#FFFFFF", caption:"rgba(255,255,255,0.85)")
    )

    static let all: [PosterStyle] = [classicModern, galleryPyrenees, galleryGreen, galleryMarmotte]
    static func style(id: String) -> PosterStyle {
        all.first{ $0.id == id } ?? galleryPyrenees
    }
}