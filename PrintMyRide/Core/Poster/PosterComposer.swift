import UIKit
import CoreText
import MapKit

final class PosterComposer {
    private let mapSvc = PosterMapService.shared
    private let routeRenderer = PosterRouteRenderer()
    private let cache = NSCache<NSString, UIImage>()

    func renderPoster(route: [CLLocationCoordinate2D],
                      title: String,
                      metrics: PosterMetrics,
                      spec: PosterSpec,
                      scale: CGFloat = 2.0) async throws -> UIImage {

        let routeHash = route.map { "\($0.latitude),\($0.longitude)" }.joined().hashValue
        let key = NSString(string: "poster-\(routeHash)-\(title.hashValue)-\(metrics.hashValue)-\(spec.hashValue)")
        if let cached = cache.object(forKey: key) { return cached }

        // 1 map
        let map = try await mapSvc.snapshot(for: route, spec: spec, scale: scale)

        // 2 project polyline to image points
        let points = try await project(route: route, onto: map, spec: spec)

        // 3 draw route
        let withRoute = routeRenderer.drawRoute(on: map, route: points, spec: spec, stroke: .label)

        // 4 compose text and metrics
        let final = drawTextAndMetrics(base: withRoute, title: title, metrics: metrics, spec: spec)

        cache.setObject(final, forKey: key)
        return final
    }

    private func project(route: [CLLocationCoordinate2D],
                         onto map: UIImage,
                         spec: PosterSpec) async throws -> [CGPoint] {

        // Build an MKMapRect transform from region used in snapshot to pixel space
        // For simplicity, we'll use a basic conversion from lat/lon to screen coordinates
        // This assumes the route coordinates are roughly in the visible region
        
        guard !route.isEmpty else { return [] }
        
        // Create a coordinate region for the route
        let lats = route.map { $0.latitude }
        let lons = route.map { $0.longitude }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        
        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon
        
        // Convert coordinates to points within the map rect
        let mapSize = spec.mapRect.size
        let points = route.map { coord in
            let x = ((coord.longitude - minLon) / lonRange) * mapSize.width
            let y = ((maxLat - coord.latitude) / latRange) * mapSize.height // flip Y
            return CGPoint(x: x, y: y)
        }
        
        return points
    }

    private func drawTextAndMetrics(base: UIImage,
                                    title: String,
                                    metrics: PosterMetrics,
                                    spec: PosterSpec) -> UIImage {

        let format = UIGraphicsImageRendererFormat()
        format.scale = base.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: base.size, format: format)
        return renderer.image { ctx in
            base.draw(in: CGRect(origin: .zero, size: base.size))
            let cg = ctx.cgContext

            // Title
            let titleRect = CGRect(x: spec.safeRect.minX,
                                   y: spec.safeRect.minY,
                                   width: spec.safeRect.width * 0.7,
                                   height: 200)
            drawText(title, in: titleRect, fontName: "NewYork-Semibold", size: 56, cg: cg)

            // Metrics band
            cg.setFillColor(UIColor.systemBackground.withAlphaComponent(0.85).cgColor)
            cg.fill(spec.metricsBandRect)

            let colW = spec.metricsBandRect.width / 4.0
            let baseY = spec.metricsBandRect.minY + 12

            drawMetric(label: "Distance",
                       value: metrics.distance,
                       x: spec.metricsBandRect.minX + 0*colW + 16,
                       y: baseY,
                       cg: cg)

            drawMetric(label: "Elevation",
                       value: metrics.elevation,
                       x: spec.metricsBandRect.minX + 1*colW + 16,
                       y: baseY,
                       cg: cg)

            drawMetric(label: "Time",
                       value: metrics.time,
                       x: spec.metricsBandRect.minX + 2*colW + 16,
                       y: baseY,
                       cg: cg)

            drawMetric(label: "Date",
                       value: metrics.date,
                       x: spec.metricsBandRect.minX + 3*colW + 16,
                       y: baseY,
                       cg: cg)
        }
    }

    private func drawText(_ text: String, in rect: CGRect, fontName: String, size: CGFloat, cg: CGContext) {
        let attr = [
            NSAttributedString.Key.font: UIFont(descriptor: UIFontDescriptor(name: fontName, size: size), size: size),
            .foregroundColor: UIColor.label
        ]
        let framesetter = CTFramesetterCreateWithAttributedString(NSAttributedString(string: text, attributes: attr))
        let path = CGPath(rect: rect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, text.count), path, nil)
        CTFrameDraw(frame, cg)
    }

    private func drawMetric(label: String, value: String, x: CGFloat, y: CGFloat, cg: CGContext) {
        let valueFont = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .semibold)
        let labelFont = UIFont.systemFont(ofSize: 14, weight: .semibold)

        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: UIColor.label
        ]
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.secondaryLabel,
            .kern: 4
        ]

        let valueStr = NSAttributedString(string: value, attributes: valueAttr)
        let labelStr = NSAttributedString(string: label.uppercased(), attributes: labelAttr)

        var ty = y
        let vSize = valueStr.size()
        valueStr.draw(at: CGPoint(x: x, y: ty))
        ty += vSize.height + 4
        labelStr.draw(at: CGPoint(x: x, y: ty))
    }
}

struct PosterMetrics: Hashable {
    let distance: String
    let elevation: String
    let time: String
    let date: String
}