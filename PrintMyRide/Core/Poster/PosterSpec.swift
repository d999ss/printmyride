import CoreGraphics
import UIKit

struct PosterSpec: Hashable {
    enum Ratio { case threeFour, fourFive }
    let ratio: Ratio
    let canvas: CGSize       // pixels for export or points for screen
    let outerMarginPct: CGFloat = 0.06
    let safeZonePct: CGFloat = 0.10
    let metricsBandPct: CGFloat = 0.15

    var posterRect: CGRect {
        CGRect(origin: .zero, size: canvas)
    }

    var outerInset: CGFloat { min(canvas.width, canvas.height) * outerMarginPct }
    var safeInset: CGFloat { min(canvas.width, canvas.height) * safeZonePct }

    var contentRect: CGRect {
        posterRect.insetBy(dx: outerInset, dy: outerInset)
    }

    var metricsBandRect: CGRect {
        let h = canvas.height * metricsBandPct
        return CGRect(x: contentRect.minX,
                      y: contentRect.maxY - h,
                      width: contentRect.width,
                      height: h)
    }

    var mapRect: CGRect {
        contentRect.insetBy(dx: 0, dy: 0)
            .inset(by: UIEdgeInsets(top: 0, left: 0, bottom: metricsBandRect.height + safeInset*0.5, right: 0))
    }

    var safeRect: CGRect {
        contentRect.insetBy(dx: safeInset, dy: safeInset)
    }
}