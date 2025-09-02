import SwiftUI
import UIKit
import CoreLocation

/// Transforms cycling routes into beautiful wall-worthy art pieces
struct ArtisticPosterRenderer {
    
    // MARK: - Poster Styles
    
    enum PosterStyle: String, CaseIterable {
        case minimalist = "minimalist"
        case vintage = "vintage" 
        case elevation = "elevation"
        case geometric = "geometric"
        case swiss = "swiss"
        
        var displayName: String {
            switch self {
            case .minimalist: return "Minimalist"
            case .vintage: return "Vintage"
            case .elevation: return "Elevation"
            case .geometric: return "Geometric"
            case .swiss: return "Swiss Design"
            }
        }
    }
    
    enum ColorPalette: String, CaseIterable {
        case monochrome = "monochrome"
        case forest = "forest"
        case sunset = "sunset"
        case ocean = "ocean"
        case alpine = "alpine"
        
        var colors: (background: Color, route: Color, text: Color) {
            switch self {
            case .monochrome:
                return (.white, .black, .black)
            case .forest:
                return (.init(red: 0.95, green: 0.97, blue: 0.95), .init(red: 0.13, green: 0.45, blue: 0.13), .init(red: 0.13, green: 0.45, blue: 0.13))
            case .sunset:
                return (.init(red: 0.99, green: 0.96, blue: 0.93), .init(red: 0.85, green: 0.33, blue: 0.18), .init(red: 0.85, green: 0.33, blue: 0.18))
            case .ocean:
                return (.init(red: 0.97, green: 0.98, blue: 0.99), .init(red: 0.12, green: 0.47, blue: 0.71), .init(red: 0.12, green: 0.47, blue: 0.71))
            case .alpine:
                return (.init(red: 0.98, green: 0.98, blue: 0.98), .init(red: 0.28, green: 0.36, blue: 0.55), .init(red: 0.28, green: 0.36, blue: 0.55))
            }
        }
    }
    
    // MARK: - Main Rendering Function
    
    @MainActor
    static func renderArtisticPoster(
        title: String,
        coordinates: [CLLocationCoordinate2D],
        distance: String,
        duration: String,
        elevation: String?,
        date: String,
        location: String?,
        style: PosterStyle = .minimalist,
        palette: ColorPalette = .monochrome,
        size: CGSize = CGSize(width: 800, height: 1200) // Portrait aspect ratio
    ) async -> UIImage? {
        
        let posterView = ArtisticPosterView(
            title: title,
            coordinates: coordinates,
            distance: distance,
            duration: duration,
            elevation: elevation,
            date: date,
            location: location,
            style: style,
            palette: palette,
            size: size
        )
        
        return ImageRenderer(content: posterView).uiImage
    }
}

// MARK: - SwiftUI Poster View

private struct ArtisticPosterView: View {
    let title: String
    let coordinates: [CLLocationCoordinate2D]
    let distance: String
    let duration: String
    let elevation: String?
    let date: String
    let location: String?
    let style: ArtisticPosterRenderer.PosterStyle
    let palette: ArtisticPosterRenderer.ColorPalette
    let size: CGSize
    
    private var colors: (background: Color, route: Color, text: Color) {
        palette.colors
    }
    
    var body: some View {
        ZStack {
            // Background
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section - Title and subtitle
                VStack(spacing: 8) {
                    Text(title.uppercased())
                        .font(.system(size: posterScale(48), weight: .black, design: .default))
                        .foregroundColor(colors.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    if let location = location {
                        Text(location.uppercased())
                            .font(.system(size: posterScale(14), weight: .medium, design: .default))
                            .foregroundColor(colors.text.opacity(0.7))
                            .kerning(2)
                    }
                }
                .padding(.top, posterScale(60))
                .padding(.horizontal, posterScale(40))
                
                Spacer()
                
                // Middle section - Route visualization
                ArtisticRouteView(
                    coordinates: coordinates,
                    style: style,
                    routeColor: colors.route,
                    size: CGSize(
                        width: size.width - posterScale(80),
                        height: size.height * 0.5
                    )
                )
                .padding(.horizontal, posterScale(40))
                
                Spacer()
                
                // Bottom section - Metrics and details
                VStack(spacing: posterScale(20)) {
                    // Metrics row
                    HStack(spacing: posterScale(30)) {
                        MetricView(value: distance, label: "DISTANCE", textColor: colors.text)
                        
                        if let elevation = elevation {
                            MetricView(value: elevation, label: "ELEVATION", textColor: colors.text)
                        }
                        
                        MetricView(value: duration, label: "TIME", textColor: colors.text)
                    }
                    
                    // Date
                    Text(date.uppercased())
                        .font(.system(size: posterScale(12), weight: .medium, design: .default))
                        .foregroundColor(colors.text.opacity(0.6))
                        .kerning(1.5)
                }
                .padding(.bottom, posterScale(60))
                .padding(.horizontal, posterScale(40))
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    private func posterScale(_ value: CGFloat) -> CGFloat {
        // Scale relative to a standard 800x1200 poster
        let baseWidth: CGFloat = 800
        let scale = size.width / baseWidth
        return value * scale
    }
}

// MARK: - Artistic Route Visualization

private struct ArtisticRouteView: View {
    let coordinates: [CLLocationCoordinate2D]
    let style: ArtisticPosterRenderer.PosterStyle
    let routeColor: Color
    let size: CGSize
    
    var body: some View {
        Canvas { context, canvasSize in
            guard !coordinates.isEmpty else { return }
            
            switch style {
            case .minimalist:
                drawMinimalistRoute(context: context, size: canvasSize)
            case .vintage:
                drawVintageRoute(context: context, size: canvasSize)
            case .elevation:
                drawElevationRoute(context: context, size: canvasSize)
            case .geometric:
                drawGeometricRoute(context: context, size: canvasSize)
            case .swiss:
                drawSwissRoute(context: context, size: canvasSize)
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    // MARK: - Style-specific drawing methods
    
    private func drawMinimalistRoute(context: GraphicsContext, size: CGSize) {
        let path = createSmoothPath(from: coordinates, in: size)
        
        context.stroke(
            path,
            with: .color(routeColor),
            style: StrokeStyle(
                lineWidth: 3.0,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
    
    private func drawVintageRoute(context: GraphicsContext, size: CGSize) {
        let path = createSmoothPath(from: coordinates, in: size)
        
        // Multiple stroke layers for vintage effect
        context.stroke(
            path,
            with: .color(routeColor.opacity(0.3)),
            style: StrokeStyle(lineWidth: 8.0, lineCap: .round)
        )
        
        context.stroke(
            path,
            with: .color(routeColor),
            style: StrokeStyle(lineWidth: 4.0, lineCap: .round)
        )
    }
    
    private func drawElevationRoute(context: GraphicsContext, size: CGSize) {
        // Variable thickness based on elevation changes
        let points = normalizeCoordinates(coordinates, to: size)
        guard points.count > 1 else { return }
        
        for i in 1..<points.count {
            let start = points[i-1]
            let end = points[i]
            
            // Simulate elevation-based thickness (can be enhanced with real elevation data)
            let thickness = 2.0 + sin(Double(i) * 0.3) * 2.0
            
            let path = Path { p in
                p.move(to: start)
                p.addLine(to: end)
            }
            
            context.stroke(
                path,
                with: .color(routeColor),
                style: StrokeStyle(
                    lineWidth: thickness,
                    lineCap: .round
                )
            )
        }
    }
    
    private func drawGeometricRoute(context: GraphicsContext, size: CGSize) {
        let points = normalizeCoordinates(coordinates, to: size)
        guard points.count > 1 else { return }
        
        // Create angular, geometric interpretation
        let simplifiedPoints = simplifyPath(points, tolerance: size.width * 0.02)
        
        let path = Path { p in
            if let first = simplifiedPoints.first {
                p.move(to: first)
                for point in simplifiedPoints.dropFirst() {
                    p.addLine(to: point)
                }
            }
        }
        
        context.stroke(
            path,
            with: .color(routeColor),
            style: StrokeStyle(
                lineWidth: 4.0,
                lineCap: .square,
                lineJoin: .miter
            )
        )
    }
    
    private func drawSwissRoute(context: GraphicsContext, size: CGSize) {
        let path = createSmoothPath(from: coordinates, in: size)
        
        // Clean, precise Swiss design aesthetic
        context.stroke(
            path,
            with: .color(routeColor),
            style: StrokeStyle(
                lineWidth: 2.0,
                lineCap: .butt,
                lineJoin: .bevel
            )
        )
        
        // Add subtle grid reference lines
        drawGrid(context: context, size: size)
    }
    
    // MARK: - Helper methods
    
    private func createSmoothPath(from coordinates: [CLLocationCoordinate2D], in size: CGSize) -> Path {
        let points = normalizeCoordinates(coordinates, to: size)
        guard points.count > 1 else { return Path() }
        
        return Path { path in
            path.move(to: points[0])
            
            if points.count == 2 {
                path.addLine(to: points[1])
            } else {
                // Create smooth curves using quadratic bezier
                for i in 1..<points.count {
                    let point = points[i]
                    
                    if i == points.count - 1 {
                        path.addLine(to: point)
                    } else {
                        let nextPoint = points[i + 1]
                        let midPoint = CGPoint(
                            x: (point.x + nextPoint.x) / 2,
                            y: (point.y + nextPoint.y) / 2
                        )
                        path.addQuadCurve(to: midPoint, control: point)
                    }
                }
            }
        }
    }
    
    private func normalizeCoordinates(_ coordinates: [CLLocationCoordinate2D], to size: CGSize) -> [CGPoint] {
        guard !coordinates.isEmpty else { return [] }
        
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!
        
        // Add padding
        let padding: CGFloat = 20
        let contentWidth = size.width - (padding * 2)
        let contentHeight = size.height - (padding * 2)
        
        return coordinates.map { coord in
            let normalizedLat = (coord.latitude - minLat) / (maxLat - minLat)
            let normalizedLon = (coord.longitude - minLon) / (maxLon - minLon)
            
            return CGPoint(
                x: padding + normalizedLon * contentWidth,
                y: padding + (1.0 - normalizedLat) * contentHeight // Flip Y coordinate
            )
        }
    }
    
    private func simplifyPath(_ points: [CGPoint], tolerance: Double) -> [CGPoint] {
        // Simple Douglas-Peucker-style simplification
        guard points.count > 2 else { return points }
        
        var simplified: [CGPoint] = [points.first!]
        
        for i in 1..<points.count-1 {
            let current = points[i]
            let last = simplified.last!
            let distance = sqrt(pow(current.x - last.x, 2) + pow(current.y - last.y, 2))
            
            if distance > tolerance {
                simplified.append(current)
            }
        }
        
        simplified.append(points.last!)
        return simplified
    }
    
    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let gridSpacing: CGFloat = 40
        let gridColor = routeColor.opacity(0.1)
        
        // Vertical lines
        for x in stride(from: 0, through: size.width, by: gridSpacing) {
            let path = Path { p in
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.stroke(path, with: .color(gridColor), style: StrokeStyle(lineWidth: 0.5))
        }
        
        // Horizontal lines
        for y in stride(from: 0, through: size.height, by: gridSpacing) {
            let path = Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(gridColor), style: StrokeStyle(lineWidth: 0.5))
        }
    }
}

// MARK: - Metric Display Component

private struct MetricView: View {
    let value: String
    let label: String
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .default))
                .foregroundColor(textColor.opacity(0.7))
                .kerning(1)
        }
    }
}