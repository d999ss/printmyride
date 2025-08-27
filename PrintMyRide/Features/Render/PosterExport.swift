import SwiftUI
import UIKit

enum PosterExport {
    static func renderPNG(route: GPXRoute, design: PosterDesign, exportScale: CGFloat = 1.0) -> Data? {
        let W = Int(design.widthInches  * CGFloat(design.dpi) * exportScale)
        let H = Int(design.heightInches * CGFloat(design.dpi) * exportScale)
        let M = Int(min(W, H)).quotientAndRemainder(dividingBy: 10_000).remainder // ignore, using margin below
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        
        // Background
        ctx.setFillColor(UIColor(design.backgroundColor.color).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        
        // Content rect with margins
        let margin = Int(CGFloat(min(W, H)) * design.marginRatio)
        let content = CGRect(x: margin, y: margin, width: W - 2*margin, height: H - 2*margin)
        
        // Route
        let path = RouteNormalizer.path(for: route, in: content)
        ctx.addPath(path)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setLineWidth(design.strokeWidthPt * exportScale)
        ctx.setStrokeColor(UIColor(design.routeColor.color).cgColor)
        ctx.strokePath()
        
        // Title and subtitle
        let title = design.title as NSString
        let subtitle = design.subtitle as NSString
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48 * exportScale, weight: .semibold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24 * exportScale, weight: .regular),
            .foregroundColor: UIColor(white: 1, alpha: 0.8),
            .paragraphStyle: paragraph
        ]
        let textWidth = CGFloat(W) - CGFloat(2*margin)
        let titleRect = CGRect(x: CGFloat(margin), y: CGFloat(H) - CGFloat(margin) - 96 * exportScale, width: textWidth, height: 60 * exportScale)
        let subRect   = CGRect(x: CGFloat(margin), y: titleRect.maxY + 4 * exportScale, width: textWidth, height: 40 * exportScale)
        title.draw(in: titleRect, withAttributes: titleAttrs)
        if !design.subtitle.isEmpty { subtitle.draw(in: subRect, withAttributes: subAttrs) }
        
        guard let img = ctx.makeImage() else { return nil }
        return UIImage(cgImage: img).pngData()
    }
}
