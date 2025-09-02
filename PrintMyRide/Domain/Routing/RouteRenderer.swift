import SwiftUI
import UIKit
import CoreLocation
import MapKit

struct RouteRenderer {
    // Simple route image for demo seeding
    @MainActor
    static func renderImage(from coords: [CLLocationCoordinate2D], size: CGSize, lineWidth: CGFloat) async -> UIImage? {
        guard coords.count > 1 else { return nil }
        
        let routeView = RouteDrawingView(coords: coords, size: size, lineWidth: lineWidth)
        
        return await ImageRenderer(content: routeView).uiImage
    }
    
    private struct RouteDrawingView: View {
        let coords: [CLLocationCoordinate2D]
        let size: CGSize
        let lineWidth: CGFloat
        
        var body: some View {
            Canvas { context, size in
                let path = Path { path in
                    let firstPoint = CGPoint(x: size.width * 0.3, y: size.height * 0.2)
                    path.move(to: firstPoint)
                    
                    for i in 1..<min(coords.count, 20) {
                        let progress = CGFloat(i) / 20.0
                        let x = size.width * (0.3 + progress * 0.4)
                        let y = size.height * (0.2 + sin(progress * 3) * 0.3 + progress * 0.4)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                context.stroke(path, with: .color(.blue), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            .frame(width: size.width, height: size.height)
            .background(Color(.systemBackground))
        }
    }
    
    static func renderPoster(
        coordinates: [CLLocationCoordinate2D],
        title: String,
        distance: String,
        duration: String,
        date: String,
        size: CGSize = CGSize(width: 400, height: 600),
        style: MapBackdropStyle = .standard,
        useMapBackground: Bool = false
    ) async -> UIImage? {
        // Move heavy rendering off main thread
        return await Task.detached(priority: .userInitiated) {
            await _renderPoster(
                coordinates: coordinates,
                title: title,
                distance: distance,
                duration: duration,
                date: date,
                size: size,
                style: style,
                useMapBackground: useMapBackground
            )
        }.value
    }
    
    private static func _renderPoster(
        coordinates: [CLLocationCoordinate2D],
        title: String,
        distance: String,
        duration: String,
        date: String,
        size: CGSize,
        style: MapBackdropStyle,
        useMapBackground: Bool
    ) async -> UIImage? {
        guard !coordinates.isEmpty else { return nil }
        
        if useMapBackground {
            // Use map as background for the entire poster
            let mapHeight = size.height * 0.65
            let mapSize = CGSize(width: size.width, height: mapHeight)
            
            guard let mapSnapshot = await MapSnapshotper.snapshot(
                coords: coordinates,
                size: mapSize,
                scale: 3.0,
                style: style
            ) else { return nil }
            
            return await renderPosterWithMap(
                mapSnapshot: mapSnapshot,
                title: title,
                distance: distance,
                duration: duration,
                date: date,
                fullSize: size
            )
        } else {
            // Use simple route rendering without map background
            return await renderImage(from: coordinates, size: size, lineWidth: 4)
        }
    }
    
    @MainActor
    private static func renderPosterWithMap(
        mapSnapshot: UIImage,
        title: String,
        distance: String,
        duration: String,
        date: String,
        fullSize: CGSize
    ) async -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: fullSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: fullSize)
            
            // Background
            cgContext.setFillColor(UIColor.systemBackground.cgColor)
            cgContext.fill(rect)
            
            // Map image
            let mapRect = CGRect(x: 0, y: 0, width: fullSize.width, height: mapSnapshot.size.height * (fullSize.width / mapSnapshot.size.width))
            mapSnapshot.draw(in: mapRect)
            
            // Text area
            let textY = mapRect.maxY + 20
            let textAreaHeight = fullSize.height - textY - 20
            let textRect = CGRect(x: 20, y: textY, width: fullSize.width - 40, height: textAreaHeight)
            
            // Draw title
            let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.label
            ]
            
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: textRect.minX, y: textRect.minY, width: textRect.width, height: titleSize.height)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Draw stats
            let statsY = titleRect.maxY + 15
            let statFont = UIFont.systemFont(ofSize: 16, weight: .medium)
            let statAttributes: [NSAttributedString.Key: Any] = [
                .font: statFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            let distanceRect = CGRect(x: textRect.minX, y: statsY, width: textRect.width, height: 20)
            distance.draw(in: distanceRect, withAttributes: statAttributes)
            
            let durationRect = CGRect(x: textRect.minX, y: statsY + 25, width: textRect.width, height: 20)
            duration.draw(in: durationRect, withAttributes: statAttributes)
            
            let dateRect = CGRect(x: textRect.minX, y: statsY + 50, width: textRect.width, height: 20)
            date.draw(in: dateRect, withAttributes: statAttributes)
        }
    }
}