import CoreGraphics

enum Simplify {
    // Ramer–Douglas–Peucker
    static func rdp(_ pts: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard pts.count > 2, epsilon > 0 else { return pts }
        var dmax: CGFloat = 0
        var index = 0
        let end = pts.count - 1

        for i in 1..<end {
            let d = perpDistance(pts[i], a: pts[0], b: pts[end])
            if d > dmax { index = i; dmax = d }
        }
        if dmax > epsilon {
            let rec1 = rdp(Array(pts[0...index]), epsilon: epsilon)
            let rec2 = rdp(Array(pts[index...end]), epsilon: epsilon)
            return Array(rec1.dropLast()) + rec2
        } else {
            return [pts.first!, pts.last!]
        }
    }

    static func perpDistance(_ p: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        if dx == 0 && dy == 0 { return hypot(p.x - a.x, p.y - a.y) }
        let t = ((p.x - a.x)*dx + (p.y - a.y)*dy) / (dx*dx + dy*dy)
        let proj = CGPoint(x: a.x + t*dx, y: a.y + t*dy)
        return hypot(p.x - proj.x, p.y - proj.y)
    }

    // Budgeted downsample (keeps ends)
    static func budget(_ pts: [CGPoint], maxPoints: Int) -> [CGPoint] {
        guard pts.count > maxPoints, maxPoints > 2 else { return pts }
        var out = [pts.first!]
        
        // Sample exactly maxPoints-2 interior points
        for i in 1..<(maxPoints-1) {
            let index = 1 + (i - 1) * (pts.count - 2) / (maxPoints - 3)
            out.append(pts[index])
        }
        
        out.append(pts.last!)
        return out
    }
}