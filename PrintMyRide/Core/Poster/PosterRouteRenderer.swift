import UIKit
import CoreImage

final class PosterRouteRenderer {
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func drawRoute(on base: UIImage,
                   route: [CGPoint], // projected into map image space
                   spec: PosterSpec,
                   stroke: UIColor = .label) -> UIImage {

        let format = UIGraphicsImageRendererFormat()
        format.scale = base.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: base.size, format: format)
        return renderer.image { ctx in
            base.draw(in: CGRect(origin: .zero, size: base.size))

            let cg = ctx.cgContext
            cg.saveGState()

            // draw route
            let path = CGMutablePath()
            if let first = route.first {
                path.move(to: first)
                for p in route.dropFirst() { path.addLine(to: p) }
            }

            cg.addPath(path)
            cg.setLineWidth(max(3, min(base.size.width, base.size.height) * 0.004))
            cg.setLineCap(.round)
            cg.setLineJoin(.round)
            cg.setStrokeColor(stroke.withAlphaComponent(0.95).cgColor)
            cg.strokePath()

            // optional inner highlight for contrast
            cg.addPath(path)
            cg.setLineWidth(max(1, min(base.size.width, base.size.height) * 0.002))
            cg.setStrokeColor(UIColor.systemBackground.withAlphaComponent(0.8).cgColor)
            cg.strokePath()

            cg.restoreGState()
        }
    }
}