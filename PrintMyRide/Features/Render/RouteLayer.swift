import SwiftUI
import CoreLocation

struct RouteLayer: View {
    let coords: [CLLocationCoordinate2D]
    let rect: CGRect
    let color: Color
    var drawTicks: Bool = true

    var body: some View {
        Canvas { ctx, size in
            guard coords.count > 1 else { return }

            let proj = Projection(coords: coords, rect: rect)
            var path = Path()
            path.move(to: proj.map(coords[0]))
            for c in coords.dropFirst() { path.addLine(to: proj.map(c)) }

            ctx.stroke(path, with: .color(color), lineWidth: max(2, rect.width*0.006))

            // Start / finish markers
            let start = proj.map(coords.first!)
            let end   = proj.map(coords.last!)
            ctx.fill(Path(ellipseIn: CGRect(x: start.x-4, y: start.y-4, width: 8, height: 8)), with: .color(color))
            let finish = Path(ellipseIn: CGRect(x: end.x-5, y: end.y-5, width: 10, height: 10))
            ctx.stroke(finish, with: .color(color), lineWidth: 2)
            ctx.fill(Path(ellipseIn: CGRect(x: end.x-4, y: end.y-4, width: 8, height: 8)), with: .color(.white))

            // Direction ticks
            if drawTicks {
                let every = max(18, coords.count/60) // ~40 ticks
                for i in stride(from: every, to: coords.count-2, by: every) { // stop before finish dot
                    let a = proj.map(coords[i-1]), b = proj.map(coords[i])
                    let ang = atan2(b.y - a.y, b.x - a.x)
                    drawTriangle(at: b, angle: ang, ctx: &ctx, color: color)
                }
            }
        }
    }

    private func drawTriangle(at p: CGPoint, angle: CGFloat, ctx: inout GraphicsContext, color: Color) {
        let size: CGFloat = 5
        var tri = Path()
        tri.move(to: .init(x: -size, y: size))
        tri.addLine(to: .init(x: size,  y: 0))
        tri.addLine(to: .init(x: -size, y: -size))
        tri.closeSubpath()
        let t = CGAffineTransform(translationX: p.x, y: p.y)
            .rotated(by: angle)
        ctx.fill(tri.applying(t), with: .color(color.opacity(0.55)))
    }

    struct Projection {
        let minLat, maxLat, minLon, maxLon, kx: Double
        let s: CGFloat, ox: CGFloat, oy: CGFloat

        init(coords: [CLLocationCoordinate2D], rect: CGRect) {
            var minLa=coords[0].latitude, maxLa=minLa, minLo=coords[0].longitude, maxLo=minLo
            for c in coords {
                minLa=min(minLa,c.latitude); maxLa=max(maxLa,c.latitude)
                minLo=min(minLo,c.longitude); maxLo=max(maxLo,c.longitude)
            }
            minLat=minLa; maxLat=maxLa; minLon=minLo; maxLon=maxLo
            kx = cos((minLa+maxLa)/2 * .pi/180)
            let srcW = (maxLon-minLon)*kx, srcH = (maxLat-minLat)
            s = min(rect.width/max(CGFloat(srcW),0.0001), rect.height/max(CGFloat(srcH),0.0001))
            ox = rect.minX + (rect.width  - CGFloat(srcW)*s)/2
            oy = rect.minY + (rect.height - CGFloat(srcH)*s)/2
        }
        func map(_ c: CLLocationCoordinate2D) -> CGPoint {
            let x = (c.longitude - minLon)*kx, y = (maxLat - c.latitude)
            return CGPoint(x: ox + CGFloat(x)*s, y: oy + CGFloat(y)*s)
        }
    }
}