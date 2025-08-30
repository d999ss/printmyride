import SwiftUI
import MapKit
import CoreLocation

struct GalleryPoster: View {
    let style: PosterStyle
    let title: String
    let payload: RoutePayload
    @State private var mapImage: UIImage?

    var body: some View {
        GeometryReader { geo in
            // Poster sheet 18×24
            let aspect: CGFloat = 18.0/24.0
            let side  = clamp(style.margins.sidePct  * geo.size.width,
                              style.margins.minSide, style.margins.maxSide)
            let vpad  = clamp(style.margins.vPct     * geo.size.height,
                              style.margins.minV,    style.margins.maxV)
            let availW = geo.size.width  - side*2
            let availH = geo.size.height - vpad*2
            let posterW = min(availW, availH*aspect)
            let posterH = posterW/aspect

            // square map box, title, caption
            let mapBox = posterW
            let spacing: CGFloat = 10

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: spacing) {
                    // MAP SQUARE – watermark covered, mute layer
                    ZStack(alignment: .bottom) {
                        if let img = mapImage {
                            Image(uiImage: img).resizable().scaledToFill()
                        } else { Color.white }
                        Rectangle().fill(Color.white.opacity(style.map.muteOpacity))
                        if style.map.hideWatermark {
                            let scale = UIScreen.main.scale
                            let coverH = max(mapBox * 0.035, (ceil(22 * scale) / scale))
                            Rectangle().fill(.white).frame(height: coverH)
                        }
                    }
                    .frame(width: mapBox, height: mapBox)
                    .clipped()
                    .overlay(
                        // route overlay
                        RouteLayer(coords: payload.coords,
                                   rect: CGRect(x: 0, y: 0, width: mapBox, height: mapBox),
                                   color: style.routeColor,
                                   drawTicks: style.route.ticks.enabled)
                    )

                    // TITLE
                    Text(title)
                        .font(.system(size: style.typography.titleSize,
                                      weight: fontWeight(style.typography.titleWeight)))
                        .foregroundStyle(style.titleColor)
                        .frame(width: posterW, alignment: .center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    // tiny gap to caption
                    Spacer().frame(height: style.caption?.gapToTitle ?? 4)

                    // CAPTION – centered, max width, single line
                    HStack(spacing: 8) {
                        ForEach(captionItems.indices, id:\.self) { i in
                            Text(captionItems[i]).lineLimit(1)
                                .minimumScaleFactor(0.85).allowsTightening(true)
                            if i < captionItems.count-1 { Text(style.caption?.bullet ?? "•").opacity(0.7) }
                        }
                    }
                    .font(.system(size: style.typography.captionSize))
                    .foregroundStyle(style.captionColor)
                    .frame(width: posterW * (style.caption?.maxWidthPct ?? 0.82), alignment: .center)

                    // Negative space at bottom
                    Spacer().frame(height: clamp((style.caption?.bottomSpacePct ?? 0.08) * posterW, 24, 56))
                }
                .background(style.panelColor)
                .frame(width: posterW, height: posterH)
                .background(style.paperColor)
                .overlay(Rectangle().stroke(.black.opacity(0.08), lineWidth: 1))
                .padding(.horizontal, side).padding(.vertical, vpad)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .task(id: "\(Int(posterW))-\(payload.coords.count)-\(style.map.terrain)") {
                mapImage = await MapKitPoster.snapshot(coords: payload.coords,
                                                       size: CGSize(width: mapBox, height: mapBox),
                                                       terrain: mapType(style.map.terrain))
            }
        }
    }

    private var captionItems: [String] {
        let tokens = style.caption?.tokens ?? ["distance","elevation","days","weather"]
        return tokens.map {
            switch $0 {
            case "distance": distanceText
            case "elevation": elevationText
            case "days": daysText
            case "weather": weatherText
            default: ""
            }
        }.filter{ !$0.isEmpty }
    }

    @AppStorage("units") private var units: String = "km"
    private var stats: StatsExtractor.Stats {
        StatsExtractor.compute(coords: payload.coords,
                               elevations: payload.elevations,
                               timestamps: payload.timestamps)
    }
    private var distanceText: String {
        units=="mi" ? String(format:"%.2f mi", stats.distanceKm*0.621371)
                    : String(format:"%.2f km", stats.distanceKm)
    }
    private var elevationText: String {
        units=="mi" ? "\(Int((stats.ascentM*3.28084).rounded())) ft"
                    : "\(Int(stats.ascentM.rounded())) m"
    }
    private var daysText: String {
        let d = max(1, Int((stats.durationSec ?? 0)/86400))
        return d == 1 ? "1 Day" : "\(d) Days"
    }
    private var weatherText: String { "Thunderstorm" }

    private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { min(hi, max(lo, v)) }
    private func fontWeight(_ s: String) -> Font.Weight {
        switch s { case "bold": return .bold; case "semibold": return .semibold; default: return .regular }
    }
    private func mapType(_ s: String) -> MKMapType {
        switch s { case "standard": return .standard; case "hybrid": return .hybrid; default: return .mutedStandard }
    }
}