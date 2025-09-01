import Foundation
import MapKit
import UIKit

final class MapSnapshotService {
    static func snapshot(coords: [CLLocationCoordinate2D], size: CGSize, completion: @escaping (UIImage?) -> Void) {
        guard !coords.isEmpty else { completion(nil); return }
        let options = MKMapSnapshotter.Options()
        options.region = RouteMapHelpers.region(fitting: coords)
        options.size = size
        options.showsBuildings = false
        options.pointOfInterestFilter = .excludingAll
        let snap = MKMapSnapshotter(options: options)
        snap.start { image, error in
            guard let base = image?.image, error == nil else { completion(nil); return }
            // draw route over snapshot
            UIGraphicsBeginImageContextWithOptions(base.size, true, base.scale)
            base.draw(at: .zero)
            if let ctx = UIGraphicsGetCurrentContext() {
                // scale coords to image space
                ctx.setLineWidth(5)
                // High-contrast route: white core + subtle outer glow
                ctx.setShadow(offset: .zero, blur: 8, color: UIColor.black.withAlphaComponent(0.6).cgColor)
                ctx.setStrokeColor(UIColor.white.cgColor)
                var first = true
                for c in coords {
                    let p = image!.point(for: c)
                    if first { ctx.move(to: p); first = false } else { ctx.addLine(to: p) }
                }
                ctx.strokePath()
            }
            let out = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            completion(out)
        }
    }
}