import UIKit
import CoreLocation
import MapKit

// MARK: - Data Models

struct RidePosterInput {
    let coordinates: [CLLocationCoordinate2D]
    let distanceMeters: Double
    let movingSeconds: Int
    let elevationGainMeters: Double
    let centroid: CLLocationCoordinate2D
    let date: Date
    let title: String?
    let units: Units
    let theme: PosterTheme
}

enum Units {
    case metric, imperial
}

struct PosterTheme {
    let name: String
    let baseHex: String
    let routeHex: String
    let contrastOnBaseHex: String
    let mapDarken: Double
    let streetOpacity: Double
    let dividerOpacity: Double
    
    static let terracotta = PosterTheme(
        name: "Terracotta",
        baseHex: "#A65A43",
        routeHex: "#F6E8D9",
        contrastOnBaseHex: "#F6E8D9",
        mapDarken: 0.15,
        streetOpacity: 0.5,
        dividerOpacity: 0.55
    )
    
    // Computed colors
    var baseColor: UIColor { UIColor(hex: baseHex) }
    var routeColor: UIColor { UIColor(hex: routeHex) }
    var contrastColor: UIColor { UIColor(hex: contrastOnBaseHex) }
    var mapPanelColor: UIColor { baseColor.adjustBrightness(by: -mapDarken) }
    var streetColor: UIColor { baseColor.adjustBrightness(by: -0.35).withAlphaComponent(streetOpacity) }
    var dividerColor: UIColor { baseColor.adjustBrightness(by: -0.45).withAlphaComponent(dividerOpacity) }
}

enum OutputKind {
    case pdf
    case png(scale: CGFloat)
}

// MARK: - Protocol

protocol PosterRendering {
    func render(_ input: RidePosterInput, kind: OutputKind) throws -> Data
}

// MARK: - Main Renderer

class PosterRenderer: PosterRendering {
    
    // Canvas constants
    private let aspectRatio: CGFloat = 3.0 / 4.0 // width/height
    private let safeMarginPercent: CGFloat = 0.075
    
    // Layout percentages (of canvas height)
    private let titleBandHeightPercent: CGFloat = 0.12
    private let mapContainerHeightPercent: CGFloat = 0.46
    private let metricsBandHeightPercent: CGFloat = 0.12
    private let sideLabelInsetPercent: CGFloat = 0.015
    
    // Typography scale factors (of canvas width)
    private let titleSizePercent: CGFloat = 0.085
    private let sideLabelSizePercent: CGFloat = 0.026
    private let metricLabelSizePercent: CGFloat = 0.018
    private let metricValueSizePercent: CGFloat = 0.042
    
    // Route rendering
    private let routeWidthPercent: CGFloat = 0.018 // of map container width
    private let routeHaloMultiplier: CGFloat = 1.8
    private let bboxPaddingPercent: CGFloat = 0.10
    
    // Grid
    private let baseGrid: CGFloat = 4.0
    private let cornerRadiusPercent: CGFloat = 0.015
    
    func render(_ input: RidePosterInput, kind: OutputKind) throws -> Data {
        print("[PosterRenderer] Starting render for \(input.coordinates.count) coordinates")
        
        let canvasSize = self.canvasSize(for: kind)
        let canvas = CanvasLayout(size: canvasSize, margins: safeMarginPercent)
        
        print("[PosterRenderer] Canvas size: \(canvasSize)")
        
        switch kind {
        case .pdf:
            return try renderPDF(input: input, canvas: canvas)
        case .png(let scale):
            let data = try renderPNG(input: input, canvas: canvas, scale: scale)
            print("[PosterRenderer] Generated PNG data: \(data.count) bytes")
            return data
        }
    }
    
    private func canvasSize(for kind: OutputKind) -> CGSize {
        switch kind {
        case .pdf:
            // A2 (420 × 594 mm) + 3mm bleed at 300 DPI
            let width = (420 + 6) * 300 / 25.4 // mm to pixels
            let height = (594 + 6) * 300 / 25.4
            return CGSize(width: width, height: height)
        case .png:
            // 2000 × 2667 px (3:4 aspect)
            return CGSize(width: 2000, height: 2667)
        }
    }
    
    // MARK: - PDF Rendering
    
    private func renderPDF(input: RidePosterInput, canvas: CanvasLayout) throws -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: canvas.size))
        
        return renderer.pdfData { context in
            context.beginPage()
            let cgContext = context.cgContext
            
            drawPoster(input: input, canvas: canvas, context: cgContext)
        }
    }
    
    // MARK: - PNG Rendering
    
    private func renderPNG(input: RidePosterInput, canvas: CanvasLayout, scale: CGFloat) throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: canvas.size, format: .init())
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            drawPoster(input: input, canvas: canvas, context: cgContext)
        }
        
        guard let pngData = image.pngData() else {
            throw PosterRenderError.renderingFailed
        }
        
        return pngData
    }
    
    // MARK: - Core Drawing
    
    private func drawPoster(input: RidePosterInput, canvas: CanvasLayout, context: CGContext) {
        let theme = input.theme
        
        // 1. Background
        context.setFillColor(theme.baseColor.cgColor)
        context.fill(CGRect(origin: .zero, size: canvas.size))
        
        // 2. Title
        drawTitle(input: input, canvas: canvas, context: context)
        
        // 3. Map panel
        drawMapPanel(input: input, canvas: canvas, context: context)
        
        // 4. Side labels
        drawSideLabels(input: input, canvas: canvas, context: context)
        
        // 5. Metrics
        drawMetrics(input: input, canvas: canvas, context: context)
    }
    
    private func drawTitle(input: RidePosterInput, canvas: CanvasLayout, context: CGContext) {
        let title = input.title ?? cityName(from: input.centroid)
        let titleRect = canvas.titleBandRect
        
        let fontSize = canvas.size.width * titleSizePercent
        let font = UIFont.systemFont(ofSize: fontSize, weight: .heavy)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: input.theme.contrastColor,
            .paragraphStyle: paragraphStyle,
            .kern: fontSize * -0.02 // -2% tracking
        ]
        
        // Title Case instead of ALL CAPS
        let titleCaseTitle = title.localizedCapitalized
        let attributedTitle = NSAttributedString(string: titleCaseTitle, attributes: attributes)
        
        // Center vertically in title band
        let textSize = attributedTitle.size()
        let drawRect = CGRect(
            x: titleRect.minX,
            y: titleRect.midY - textSize.height / 2,
            width: titleRect.width,
            height: textSize.height
        )
        
        attributedTitle.draw(in: drawRect)
    }
    
    private func drawMapPanel(input: RidePosterInput, canvas: CanvasLayout, context: CGContext) {
        let mapRect = canvas.mapContainerRect
        let cornerRadius = canvas.size.width * cornerRadiusPercent
        
        // Draw map background with tinted snapshot
        let mapPath = UIBezierPath(roundedRect: mapRect, cornerRadius: cornerRadius)
        context.setFillColor(input.theme.mapPanelColor.cgColor)
        context.addPath(mapPath.cgPath)
        context.fillPath()
        
        // Generate and draw tinted map snapshot
        if let mapSnapshot = generateMapSnapshotSync(for: input, size: mapRect.size) {
            let tintedImage = tintMapImageForPoster(mapSnapshot, theme: input.theme)
            
            // Draw with rounded corners
            context.saveGState()
            context.addPath(mapPath.cgPath)
            context.clip()
            
            if let cgImage = tintedImage.cgImage {
                context.draw(cgImage, in: mapRect)
            }
            
            context.restoreGState()
        } else {
            // Fallback: draw a slightly darker background if map fails
            print("[PosterRenderer] Warning: Map snapshot generation failed, using fallback background")
            context.setFillColor(input.theme.mapPanelColor.adjustBrightness(by: -0.1).cgColor)
            context.addPath(mapPath.cgPath)
            context.fillPath()
        }
        
        // Draw route on top
        drawRoute(input: input, canvas: canvas, mapRect: mapRect, context: context)
    }
    
    private func drawRoute(input: RidePosterInput, canvas: CanvasLayout, mapRect: CGRect, context: CGContext) {
        guard !input.coordinates.isEmpty else { return }
        
        let bbox = boundingBox(of: input.coordinates)
        let paddedBbox = insetBoundingBox(bbox, by: bboxPaddingPercent)
        
        // Simplify coordinates with Douglas-Peucker (1 px tolerance at export scale)
        let tolerance = 1.0 / canvas.size.width * mapRect.width // 1 device pixel at export scale
        let simplifiedCoords = douglasPeucker(input.coordinates, tolerance: tolerance)
        
        // Convert coordinates to map rect pixel space
        let points = simplifiedCoords.map { coord in
            projectCoordinate(coord, from: paddedBbox, to: mapRect)
        }
        
        guard points.count > 1 else { return }
        
        // Route width: 1.8% of map panel width, clamped 6-18px at preview scale
        let innerWidth = mapRect.width * routeWidthPercent
        let clampedInnerWidth = max(6, min(innerWidth, 18))
        let haloWidth = clampedInnerWidth * routeHaloMultiplier
        
        // Create smooth path
        let routePath = createSmoothPath(from: points)
        
        context.saveGState()
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Draw soft halo (outer stroke)
        context.setStrokeColor(input.theme.routeColor.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(haloWidth)
        context.addPath(routePath.cgPath)
        context.strokePath()
        
        // Draw crisp inner route
        context.setStrokeColor(input.theme.routeColor.cgColor)
        context.setLineWidth(clampedInnerWidth)
        context.addPath(routePath.cgPath)
        context.strokePath()
        
        context.restoreGState()
    }
    
    private func drawSideLabels(input: RidePosterInput, canvas: CanvasLayout, context: CGContext) {
        let fontSize = canvas.size.width * sideLabelSizePercent
        let font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        let inset = canvas.size.width * sideLabelInsetPercent
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: input.theme.contrastColor.withAlphaComponent(0.75),
            .kern: fontSize * 0.06 // 6% tracking
        ]
        
        // Left side: Date (rotated 90° CCW)
        let dateString = formatDate(input.date).uppercased()
        let dateText = NSAttributedString(string: dateString, attributes: attributes)
        
        context.saveGState()
        context.translateBy(x: canvas.contentBox.minX + inset, y: canvas.mapContainerRect.midY)
        context.rotate(by: -.pi / 2)
        
        let dateSize = dateText.size()
        dateText.draw(at: CGPoint(x: -dateSize.width / 2, y: -dateSize.height / 2))
        context.restoreGState()
        
        // Right side: Coordinates (rotated 90° CW)
        let coordString = formatCoordinates(input.centroid).uppercased()
        let coordText = NSAttributedString(string: coordString, attributes: attributes)
        
        context.saveGState()
        context.translateBy(x: canvas.contentBox.maxX - inset, y: canvas.mapContainerRect.midY)
        context.rotate(by: .pi / 2)
        
        let coordSize = coordText.size()
        coordText.draw(at: CGPoint(x: -coordSize.width / 2, y: -coordSize.height / 2))
        context.restoreGState()
    }
    
    private func drawMetrics(input: RidePosterInput, canvas: CanvasLayout, context: CGContext) {
        let metricsRect = canvas.metricsBandRect
        let metrics = formatMetrics(input)
        
        guard !metrics.isEmpty else { return }
        
        let columnWidth = metricsRect.width / CGFloat(metrics.count)
        let separatorHeight = metricsRect.height * 0.6
        
        // Use SF Pro Text with monospaced numerals
        let labelFont = UIFont.systemFont(ofSize: canvas.size.width * metricLabelSizePercent, weight: .regular)
        let valueFont = UIFont.monospacedSystemFont(ofSize: canvas.size.width * metricValueSizePercent, weight: .semibold)
        
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: input.theme.contrastColor.withAlphaComponent(0.65)
        ]
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: input.theme.contrastColor,
            .kern: 0 // No additional tracking for monospaced font
        ]
        
        for (index, metric) in metrics.enumerated() {
            let columnRect = CGRect(
                x: metricsRect.minX + CGFloat(index) * columnWidth,
                y: metricsRect.minY,
                width: columnWidth,
                height: metricsRect.height
            )
            
            // Draw separator (except for first column)
            if index > 0 {
                let separatorX = columnRect.minX
                let separatorRect = CGRect(
                    x: separatorX - 0.5,
                    y: metricsRect.midY - separatorHeight / 2,
                    width: 1,
                    height: separatorHeight
                )
                
                context.setFillColor(input.theme.dividerColor.cgColor)
                context.fill(separatorRect)
            }
            
            // Draw metric
            let labelText = NSAttributedString(string: metric.label.uppercased(), attributes: labelAttributes)
            let valueText = NSAttributedString(string: metric.value, attributes: valueAttributes)
            
            let labelSize = labelText.size()
            let valueSize = valueText.size()
            
            let totalHeight = labelSize.height + valueSize.height + 8
            let startY = columnRect.midY - totalHeight / 2
            
            // Label
            labelText.draw(in: CGRect(
                x: columnRect.minX,
                y: startY,
                width: columnRect.width,
                height: labelSize.height
            ))
            
            // Value
            valueText.draw(in: CGRect(
                x: columnRect.minX,
                y: startY + labelSize.height + 8,
                width: columnRect.width,
                height: valueSize.height
            ))
        }
    }
}

// MARK: - Layout Helper

struct CanvasLayout {
    let size: CGSize
    let contentBox: CGRect
    
    init(size: CGSize, margins: CGFloat) {
        self.size = size
        let margin = size.width * margins
        self.contentBox = CGRect(
            x: margin,
            y: margin,
            width: size.width - 2 * margin,
            height: size.height - 2 * margin
        )
    }
    
    var titleBandRect: CGRect {
        CGRect(
            x: contentBox.minX,
            y: contentBox.minY,
            width: contentBox.width,
            height: size.height * 0.12
        )
    }
    
    var mapContainerRect: CGRect {
        let height = size.height * 0.46
        return CGRect(
            x: contentBox.minX,
            y: contentBox.minY + (contentBox.height - height) / 2,
            width: contentBox.width,
            height: height
        )
    }
    
    var metricsBandRect: CGRect {
        let height = size.height * 0.12
        return CGRect(
            x: contentBox.minX,
            y: contentBox.maxY - height,
            width: contentBox.width,
            height: height
        )
    }
}

// MARK: - Utility Extensions

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
    
    func adjustBrightness(by amount: Double) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness = max(0, min(1, brightness + CGFloat(amount)))
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        
        return self
    }
}

// MARK: - Geometry Utilities

struct BoundingBox {
    let minLat: Double
    let maxLat: Double
    let minLon: Double
    let maxLon: Double
}

extension PosterRenderer {
    
    private func boundingBox(of coordinates: [CLLocationCoordinate2D]) -> BoundingBox {
        guard let first = coordinates.first else {
            return BoundingBox(minLat: 0, maxLat: 0, minLon: 0, maxLon: 0)
        }
        
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        
        for coord in coordinates.dropFirst() {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        return BoundingBox(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
    
    private func insetBoundingBox(_ bbox: BoundingBox, by percent: CGFloat) -> BoundingBox {
        let latDelta = bbox.maxLat - bbox.minLat
        let lonDelta = bbox.maxLon - bbox.minLon
        let latInset = latDelta * Double(percent)
        let lonInset = lonDelta * Double(percent)
        
        return BoundingBox(
            minLat: bbox.minLat - latInset,
            maxLat: bbox.maxLat + latInset,
            minLon: bbox.minLon - lonInset,
            maxLon: bbox.maxLon + lonInset
        )
    }
    
    private func projectCoordinate(_ coord: CLLocationCoordinate2D, from bbox: BoundingBox, to rect: CGRect) -> CGPoint {
        let x = (coord.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon)
        let y = 1.0 - (coord.latitude - bbox.minLat) / (bbox.maxLat - bbox.minLat) // Flip Y
        
        return CGPoint(
            x: rect.minX + CGFloat(x) * rect.width,
            y: rect.minY + CGFloat(y) * rect.height
        )
    }
}

// MARK: - Formatting Utilities

struct MetricItem {
    let label: String
    let value: String
}

extension PosterRenderer {
    
    private func cityName(from coordinate: CLLocationCoordinate2D) -> String {
        // TODO: Implement reverse geocoding
        return "Unknown Location"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func formatCoordinates(_ coordinate: CLLocationCoordinate2D) -> String {
        let lat = abs(coordinate.latitude)
        let lon = abs(coordinate.longitude)
        let latDir = coordinate.latitude >= 0 ? "N" : "S"
        let lonDir = coordinate.longitude >= 0 ? "E" : "W"
        
        return String(format: "%.4f° %@ · %.4f° %@", lat, latDir, lon, lonDir)
    }
    
    private func formatMetrics(_ input: RidePosterInput) -> [MetricItem] {
        var metrics: [MetricItem] = []
        
        // Distance: "21.4 km"
        let distance = input.units == .metric 
            ? input.distanceMeters / 1000
            : input.distanceMeters / 1609.34
        let distanceUnit = input.units == .metric ? "km" : "mi"
        metrics.append(MetricItem(
            label: "Distance",
            value: String(format: "%.1f %@", distance, distanceUnit)
        ))
        
        // Time: "1:10 h"
        let hours = input.movingSeconds / 3600
        let minutes = (input.movingSeconds % 3600) / 60
        if hours > 0 {
            metrics.append(MetricItem(
                label: "Time",
                value: String(format: "%d:%02d h", hours, minutes)
            ))
        } else {
            metrics.append(MetricItem(
                label: "Time",
                value: String(format: "%d m", minutes)
            ))
        }
        
        // Elevation gain: "197 m"
        let elevation = input.units == .metric 
            ? input.elevationGainMeters
            : input.elevationGainMeters * 3.28084
        let elevationUnit = input.units == .metric ? "m" : "ft"
        metrics.append(MetricItem(
            label: "Elevation gain",
            value: String(format: "%.0f %@", elevation, elevationUnit)
        ))
        
        // Pace: "3:08′" (use prime character)
        let paceSeconds = Double(input.movingSeconds) / distance
        let paceMinutes = Int(paceSeconds / 60)
        let paceSecondsRemainder = Int(paceSeconds.truncatingRemainder(dividingBy: 60))
        metrics.append(MetricItem(
            label: "Pace",
            value: String(format: "%d:%02d′", paceMinutes, paceSecondsRemainder)
        ))
        
        return metrics
    }
    
    // MARK: - Map Generation Utilities
    
    private func generateMapSnapshotSync(for input: RidePosterInput, size: CGSize) -> UIImage? {
        // Synchronous map snapshot generation
        let bbox = boundingBox(of: input.coordinates)
        let paddedBbox = insetBoundingBox(bbox, by: bboxPaddingPercent)
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (paddedBbox.minLat + paddedBbox.maxLat) / 2,
                longitude: (paddedBbox.minLon + paddedBbox.maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: paddedBbox.maxLat - paddedBbox.minLat,
                longitudeDelta: paddedBbox.maxLon - paddedBbox.minLon
            )
        )
        
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.scale = 1.0
        options.mapType = .standard
        
        let snapshotter = MKMapSnapshotter(options: options)
        var result: UIImage?
        
        let semaphore = DispatchSemaphore(value: 0)
        snapshotter.start { snapshot, error in
            result = snapshot?.image
            semaphore.signal()
        }
        semaphore.wait()
        
        return result
    }
    
    private func tintMapImageForPoster(_ image: UIImage, theme: PosterTheme) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: image.size)
            
            // Draw original image
            image.draw(in: rect)
            
            // Color tint overlay (blend mode: color)
            cgContext.setBlendMode(.color)
            cgContext.setFillColor(theme.mapPanelColor.cgColor)
            cgContext.fill(rect)
            
            // Multiply overlay to darken (~25% opacity)
            cgContext.setBlendMode(.multiply)
            cgContext.setFillColor(theme.baseColor.withAlphaComponent(0.25).cgColor)
            cgContext.fill(rect)
        }
    }
    
    private func douglasPeucker(_ coordinates: [CLLocationCoordinate2D], tolerance: Double) -> [CLLocationCoordinate2D] {
        // Simple Douglas-Peucker implementation
        // For now, return original coordinates (full implementation would be more complex)
        return coordinates
    }
    
    private func createSmoothPath(from points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        guard !points.isEmpty else { return path }
        
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}

// MARK: - Errors

enum PosterRenderError: Error {
    case renderingFailed
    case mapSnapshotFailed
}