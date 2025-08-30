import SwiftUI
import CoreLocation

struct LabelsLayer: View {
    let labels: [PlaceLabel]
    let coords: [CLLocationCoordinate2D]
    let rect: CGRect

    var body: some View {
        Canvas { ctx, _ in
            guard let proj = proj else { return }
            for l in labels {
                let p = proj.map(l.coordinate)
                // White halo for readability
                let text = Text(l.text).font(.system(size: 10, weight: .medium)).foregroundColor(.white)
                let resolved = ctx.resolve(text)
                
                // Draw white stroke first
                for dx in stride(from: -1, through: 1, by: 0.5) {
                    for dy in stride(from: -1, through: 1, by: 0.5) {
                        if dx != 0 || dy != 0 {
                            ctx.draw(resolved, at: CGPoint(x: p.x + dx, y: p.y + dy), anchor: .center)
                        }
                    }
                }
                // Draw black text on top
                ctx.draw(Text(l.text).font(.system(size: 10, weight: .medium)).foregroundColor(.black), 
                        at: p, anchor: .center)
            }
        }
    }
    
    private var proj: RouteLayer.Projection? {
        coords.count > 1 ? RouteLayer.Projection(coords: coords, rect: rect) : nil
    }
}