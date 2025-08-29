import SwiftUI
import MapKit
import CoreLocation

struct ClassicMapPoster: View {
    let design: PosterDesign
    let title: String
    let payload: RoutePayload
    let mode: PosterRenderMode
    var terrain: MapTerrain = .muted
    var labels: [PlaceLabel] = []
    var callouts: [MapCallout] = []
    var drawDirectionTicks: Bool = true

    @State private var mapImage: UIImage?
    @AppStorage("units") private var units: String = "mi"

    var body: some View {
        GeometryReader { geo in
            let wall = geo.size
            // 18×24 paper with side/bottom breathing room
            let aspect: CGFloat = 18/24
            let side: CGFloat = 20, vpad: CGFloat = 16, topBar: CGFloat = 44
            let availW = wall.width - side*2
            let availH = wall.height - topBar - vpad*2
            let posterW = min(availW, availH*aspect)
            let posterH = posterW/aspect

            // footer a touch taller so labels never clip
            let footerH = max(posterH * 0.18, 76)        // was 0.16
            let mapH    = posterH - footerH

            // route rect inset so line/dots don't touch edge
            let insetPct: CGFloat = 0.03
            let originX = (wall.width - posterW)/2 + side
            let originY = (wall.height - posterH)/2 + vpad
            let mapRect  = CGRect(x: originX, y: originY, width: posterW, height: mapH)
            let routeRect = mapRect.insetBy(dx: posterW*insetPct, dy: mapH*insetPct)

            ZStack {
                if mode == .editor { Color.black.ignoresSafeArea() }

                VStack(spacing: 0) {
                    // MAP (muted; watermark cover is scale-aware)
                    ZStack(alignment: .bottom) {
                        if let img = mapImage {
                            Image(uiImage: img).resizable().scaledToFill()
                        } else { Color.white }
                        Rectangle().fill(Color.white.opacity(0.06)) // soften tiles
                        let scale = UIScreen.main.scale
                        let cover = (ceil(22 * scale) / scale)       // ~22pt at device scale
                        Rectangle().fill(Color.white).frame(height: cover)
                    }
                    .frame(height: mapH)
                    .clipped()

                    // FOOTER – clean grid, black on white
                    PosterFooterGrid(title: title,
                                     date: payload.timestamps.first,
                                     distanceText: distanceString(km: stats.distanceKm),
                                     timeText:     timeString(sec: stats.durationSec ?? 0),
                                     avgText:      avgString(kmh: stats.avgKmh),
                                     gainText:     elevString(m: stats.ascentM))
                        .frame(height: footerH)
                        .background(Color.white)
                        .overlay(Rectangle().fill(Color(.separator)).frame(height: 0.5), alignment: .top)
                }
                .frame(width: posterW, height: posterH)
                .overlay(Rectangle().stroke(.white.opacity(0.08), lineWidth: 1))
                .padding(.horizontal, side).padding(.vertical, vpad)

                // ROUTE overlay (uses inset rect)
                RouteLayer(coords: payload.coords,
                           rect: routeRect,
                           color: Color(red: 0xFC/255, green: 0x4C/255, blue: 0x02/255),
                           drawTicks: drawDirectionTicks)

                // LABELS & CALLOUTS (optional)
                LabelsLayer(labels: labels,   coords: payload.coords, rect: routeRect)
                CalloutsLayer(callouts: callouts, coords: payload.coords, rect: routeRect)
            }
            // snapshot at final size
            .task(id: "\(Int(posterW))x\(Int(mapH))-\(payload.coords.count)-\(terrain.rawValue)") {
                mapImage = await MapKitPoster.snapshot(coords: payload.coords,
                                                       size: CGSize(width: posterW, height: mapH),
                                                       terrain: terrain)
            }
        }
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
}