import SwiftUI
import UIKit
import MapKit
import CoreLocation

enum PosterStyle: Int { case pure = 0, classic = 1 }

enum PosterRenderMode { case editor, export }

struct PosterPreview: View {
    let design: PosterDesign
    let posterTitle: String?
    var mode: PosterRenderMode = .editor

    // Either/or sources
    let route: GPXRoute?
    let payload: RoutePayload?

    private var coords: [CLLocationCoordinate2D] {
        if let p = payload, p.hasData { return p.coords }
        return route?.coordinates ?? []   // your GPXRoute+Ext mapping
    }
    private var elevations: [Double] { payload?.elevations ?? route?.elevations ?? [] }
    private var timestamps: [Date]  { payload?.timestamps ?? route?.timestamps ?? [] }

    var body: some View {
        ClassicMapPoster(design: design,
                         title: posterTitle ?? "My Ride",
                         payload: payload ?? RoutePayload(coords: coords, elevations: elevations, timestamps: timestamps),
                         mode: mode)
#if DEBUG
        .overlay(alignment: .topLeading) {
            Text("Coords: \(coords.count)\nMap: \(coords.count > 1 ? "✓" : "✖︎")")
                .font(.caption2).foregroundStyle(.red).padding(6)
        }
#endif
    }
}