import SwiftUI
import UIKit
import CoreLocation

/// Simple artistic poster renderer that actually works
struct SimpleArtisticPoster {
    
    static func render(
        title: String,
        coordinates: [CLLocationCoordinate2D],
        size: CGSize = CGSize(width: 800, height: 1200)
    ) -> UIImage? {
        guard !coordinates.isEmpty else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Background
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Title at top
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: 80,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Draw artistic route
            drawArtisticRoute(coordinates: coordinates, in: ctx, size: size)
            
            // Bottom text
            let dateText = Date().formatted(date: .abbreviated, time: .omitted)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            
            let dateSize = dateText.size(withAttributes: dateAttributes)
            let dateRect = CGRect(
                x: (size.width - dateSize.width) / 2,
                y: size.height - 100,
                width: dateSize.width,
                height: dateSize.height
            )
            dateText.draw(in: dateRect, withAttributes: dateAttributes)
        }
    }
    
    private static func drawArtisticRoute(
        coordinates: [CLLocationCoordinate2D],
        in context: CGContext,
        size: CGSize
    ) {
        // Convert coordinates to normalized points
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max() else { return }
        
        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon
        
        // Create padding for the route
        let padding: CGFloat = 100
        let routeWidth = size.width - (padding * 2)
        let routeHeight = size.height - 400 // Leave space for title and bottom text
        let routeY: CGFloat = 200 // Start below title
        
        // Convert to screen points
        let points = coordinates.map { coord in
            let normalizedLat = (coord.latitude - minLat) / latRange
            let normalizedLon = (coord.longitude - minLon) / lonRange
            
            return CGPoint(
                x: padding + normalizedLon * routeWidth,
                y: routeY + (1.0 - normalizedLat) * routeHeight
            )
        }
        
        guard points.count > 1 else { return }
        
        // Draw shadow
        context.setStrokeColor(UIColor.black.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(12)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        context.beginPath()
        context.move(to: CGPoint(x: points[0].x + 2, y: points[0].y + 2))
        for point in points.dropFirst() {
            context.addLine(to: CGPoint(x: point.x + 2, y: point.y + 2))
        }
        context.strokePath()
        
        // Draw main route line
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(4)
        
        context.beginPath()
        context.move(to: points[0])
        for point in points.dropFirst() {
            context.addLine(to: point)
        }
        context.strokePath()
        
        // Draw start and end markers
        // Start marker (green)
        context.setFillColor(UIColor.systemGreen.cgColor)
        context.fillEllipse(in: CGRect(x: points[0].x - 8, y: points[0].y - 8, width: 16, height: 16))
        
        // End marker (red)
        if let lastPoint = points.last {
            context.setFillColor(UIColor.systemRed.cgColor)
            context.fillEllipse(in: CGRect(x: lastPoint.x - 8, y: lastPoint.y - 8, width: 16, height: 16))
        }
    }
}