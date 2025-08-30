import SwiftUI
import MapKit
import CoreLocation

struct ClassicMapPoster: View {
    let style: PosterStyle
    let title: String
    let payload: RoutePayload
    let mode: PosterRenderMode
    var labels: [PlaceLabel] = []
    var callouts: [MapCallout] = []

    @State private var mapImage: UIImage?
    @AppStorage("units") private var units: String = "mi"

    var body: some View {
        GeometryReader { geo in
            let wall = geo.size
            // --- Poster geometry
            let aspect: CGFloat = 18.0/24.0
            let availW = wall.width
            let availH = wall.height
            let posterW        = snap(min(availW, availH*aspect))
            let posterH        = snap(posterW/aspect)
            // a touch taller footer so it never clips
            let footerH        = snap(max(posterH * 0.18, 80))
            let mapH           = snap(posterH - footerH)
            // small inset so route/dots never kiss edges
            let insetPct: CGFloat = 0.05
            // hide Apple watermark with no visible band
            let scale  = UIScreen.main.scale
            let coverH = max(mapH * 0.035, (ceil(28 * scale) / scale))

            // frame rects
            let originX = (wall.width  - posterW)/2
            let originY = (wall.height - posterH)/2
            let mapRect  = CGRect(x: originX, y: originY, width: posterW, height: mapH)
            let routeRect = mapRect.insetBy(dx: posterW*insetPct, dy: mapH*insetPct)

            ZStack {
                if mode == .editor { Color.black.ignoresSafeArea() }

                // ---------- ONE white "paper" surface ----------
                ZStack {
                    Color.white                               // the paper itself

                    VStack(spacing: 0) {
                        // MAP: draw slightly taller and slide UNDER footer
                        ZStack {
                            if let img = mapImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.white
                            }
                            // gentle mute so route pops
                            Rectangle().fill(Color.white.opacity(style.map.muteOpacity))
                        }
                        // pull the map down by the cover height so it hides the © line under footer
                        .padding(.bottom, -coverH)
                        .frame(height: mapH + coverH)
                        .clipped()

                        // FOOTER: clean, no top rule
                        if style.footer?.enabled == true {
                            PosterFooterGrid(style: style,
                                             title: title,
                                             date: payload.timestamps.first,
                                             distanceText: distanceString(km: stats.distanceKm),
                                             timeText:     timeString(sec: stats.durationSec ?? 0),
                                             avgText:      avgString(kmh: stats.avgKmh),
                                             gainText:     elevString(m: stats.ascentM))
                                .frame(height: footerH)
                        }
                    }
                }
                .frame(width: posterW, height: posterH)
                .overlay(Rectangle().stroke(.black.opacity(0.04), lineWidth: 1))

                // ROUTE overlay (uses inset rect)
                RouteLayer(coords: payload.coords,
                           rect: routeRect,
                           color: style.routeColor,
                           drawTicks: style.route.ticks.enabled)
                // Optional: labels/callouts
                LabelsLayer(labels: labels,   coords: payload.coords, rect: routeRect)
                CalloutsLayer(callouts: callouts, coords: payload.coords, rect: routeRect)
            }
            // map snapshot at final size
            .task(id: "\(Int(posterW))x\(Int(mapH))-\(payload.coords.count)-\(style.map.terrain)") {
                mapImage = await MapKitPoster.snapshot(coords: payload.coords,
                                                       size: CGSize(width: posterW, height: mapH),
                                                       terrain: mapType(style.map.terrain))
            }
        }
    }

    // MARK: helpers

    private func snap(_ v: CGFloat) -> CGFloat {
        let s = UIScreen.main.scale
        return (round(v * s) / s)
    }
    
    private func dynamicSideGutter(for width: CGFloat) -> CGFloat {
        // ~6.5% of screen width, min 24pt, max 36pt, snapped to pixel grid
        let raw = max(24, min(36, width * 0.065))
        return snap(raw)
    }
    
    private func dynamicVerticalGutter(for height: CGFloat) -> CGFloat {
        // ~3% of height, clamped 16–28pt
        let raw = max(16, min(28, height * 0.03))
        return snap(raw)
    }

    // MARK: stats/format
    private var stats: StatsExtractor.Stats {
        StatsExtractor.compute(coords: payload.coords,
                               elevations: payload.elevations,
                               timestamps: payload.timestamps)
    }
    private func distanceString(km: Double) -> String { units=="mi" ? String(format:"%.1f mi", km*0.621371) : String(format:"%.1f km", km) }
    private func avgString(kmh: Double?) -> String {
        guard let v = kmh else { return units=="mi" ? "-- mph" : "-- km/h" }
        return units=="mi" ? String(format:"%.1f mph", v*0.621371) : String(format:"%.1f km/h", v)
    }
    private func elevString(m: Double) -> String { units=="mi" ? "\(Int((m*3.28084).rounded())) ft" : "\(Int(m.rounded())) m" }
    private func timeString(sec: Double) -> String { let s=Int(sec), h=s/3600, m=(s%3600)/60; return h>0 ? String(format:"%d:%02d",h,m) : "\(m) min" }
    
    private func mapType(_ s: String) -> MKMapType {
        switch s { case "standard": return .standard; case "hybrid": return .hybrid; default: return .mutedStandard }
    }
}