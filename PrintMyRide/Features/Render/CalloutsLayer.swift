import SwiftUI
import CoreLocation

struct CalloutsLayer: View {
    let callouts: [MapCallout]
    let coords: [CLLocationCoordinate2D]
    let rect: CGRect

    var body: some View {
        Canvas { ctx, _ in
            guard let proj = proj else { return }
            for c in callouts {
                let p = proj.map(c.coordinate)
                // Leader line
                var line = Path()
                line.move(to: p)
                line.addLine(to: CGPoint(x: p.x+36, y: p.y-24))
                ctx.stroke(line, with: .color(.orange), lineWidth: 1)

                // Label box
                let box = CGRect(x: p.x+36, y: p.y-40, width: 80, height: 18)
                ctx.fill(Path(roundedRect: box, cornerRadius: 2), with: .color(.white))
                ctx.stroke(Path(roundedRect: box, cornerRadius: 2), with: .color(.orange), lineWidth: 1)
                
                // Text
                let t = Text(c.label).font(.system(size: 10, weight: .semibold)).foregroundColor(.black)
                ctx.draw(t, in: box.insetBy(dx: 4, dy: 2))
            }
        }
    }
    
    private var proj: RouteLayer.Projection? {
        coords.count > 1 ? RouteLayer.Projection(coords: coords, rect: rect) : nil
    }
}