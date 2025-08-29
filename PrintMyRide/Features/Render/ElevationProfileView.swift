import SwiftUI

struct ElevationProfileView: View {
    let elevations: [Double]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            if let minE = elevations.min(), let maxE = elevations.max(), maxE > minE, elevations.count > 1 {
                let (path, area) = createPaths(w: w, h: h, minE: minE, maxE: maxE)
                ZStack(alignment: .bottom) {
                    area.fill(Color(red: 0xFC/255, green: 0x4C/255, blue: 0x02/255))
                    path.stroke(Color(red: 0xFC/255, green: 0x4C/255, blue: 0x02/255), lineWidth: 1.0)
                }
            }
        }
    }
    
    private func createPaths(w: CGFloat, h: CGFloat, minE: Double, maxE: Double) -> (Path, Path) {
        let yTransform: (Double) -> CGFloat = { e in
            let t = (e - minE) / (maxE - minE)
            return h - CGFloat(t) * h
        }
        
        var path = Path()
        let step = w / CGFloat(elevations.count - 1)
        path.move(to: CGPoint(x: 0, y: yTransform(elevations[0])))
        for i in 1..<elevations.count {
            path.addLine(to: CGPoint(x: CGFloat(i)*step, y: yTransform(elevations[i])))
        }
        
        var area = path
        area.addLine(to: CGPoint(x: w, y: h))
        area.addLine(to: CGPoint(x: 0, y: h))
        area.closeSubpath()
        
        return (path, area)
    }
}