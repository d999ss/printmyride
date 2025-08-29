import SwiftUI
import CoreLocation

struct CanvasView: View {
    let design: PosterDesign
    let route: GPXRoute?
    var drawBackground: Bool = true
    @State private var zoom = ZoomState()
    @State private var baseOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                // background
                if drawBackground {
                    ctx.fill(Path(CGRect(origin: .zero, size: size)),
                             with: .color(design.backgroundColor.color))
                }

                guard let coords = route?.coordinates, !coords.isEmpty else { 
                    RenderStats.shared.pointsPre = 0
                    RenderStats.shared.pointsPost = 0
                    return 
                }

                // 1) Project into planar space (equirectangular)
                let lat0 = coords.reduce(0.0, { $0 + $1.latitude }) / Double(coords.count)
                let kx = cos(lat0 * .pi/180)
                let minLat = coords.map(\.latitude).min()!
                let minLon = coords.map(\.longitude).min()!
                var pts = coords.map { c in
                    CGPoint(x: (c.longitude - minLon) * kx,
                            y: (c.latitude  - minLat))
                }

                // Track pre-simplification count
                RenderStats.shared.pointsPre = pts.count

                // 2) Simplify for speed/cleanliness
                let viewDiag = hypot(size.width, size.height)
                pts = Simplify.rdp(pts, epsilon: viewDiag * 0.001) // ~0.1% of diagonal
                pts = Simplify.budget(pts, maxPoints: 4000)
                
                // Track post-simplification count
                RenderStats.shared.pointsPost = pts.count

                // 3) Fit into content rect (keep aspect; flip Y so north is up)
                let srcBB = CGRect(x: pts.map(\.x).min()!, y: pts.map(\.y).min()!,
                                   width:  pts.map(\.x).max()! - pts.map(\.x).min()!,
                                   height: pts.map(\.y).max()! - pts.map(\.y).min()!)
                let content = RenderMath.contentRect(in: size, margins: design.margins)
                let sx = content.width / max(srcBB.width,  1e-6)
                let sy = content.height / max(srcBB.height, 1e-6)
                let s = min(sx, sy)
                let fitted = CGSize(width: srcBB.width*s, height: srcBB.height*s)
                let origin = CGPoint(x: content.minX + (content.width  - fitted.width)  / 2,
                                     y: content.minY + (content.height - fitted.height) / 2)

                func map(_ p: CGPoint) -> CGPoint {
                    let x = (p.x - srcBB.minX) * s + origin.x
                    let y = (srcBB.maxY - p.y) * s + origin.y // flip Y
                    return CGPoint(x: x, y: y)
                }

                // 4) Build path
                var path = Path()
                path.move(to: map(pts[0]))
                for p in pts.dropFirst() { path.addLine(to: map(p)) }

                // 5) Stroke
                let style = StrokeStyle(lineWidth: max(0.25, design.strokeWidthPt),
                                        lineCap: RenderMath.cgCap(from: design.lineCap))
                ctx.stroke(path, with: .color(design.routeColor.color), style: style)

                // 6) Start/End markers (subtle)
                if let first = pts.first, let last = pts.last {
                    let r: CGFloat = max(2, design.strokeWidthPt * 1.25)
                    let start = Path(ellipseIn: CGRect(x: map(first).x - r, y: map(first).y - r, width: 2*r, height: 2*r))
                    let end   = Path(ellipseIn: CGRect(x: map(last).x  - r, y: map(last).y  - r, width: 2*r, height: 2*r))
                    ctx.fill(start, with: .color(design.routeColor.color.opacity(0.9)))
                    ctx.stroke(end, with: .color(design.routeColor.color.opacity(0.7)))
                }

                // Optional: grid overlay is drawn in PosterPreview
            }
            .scaleEffect(zoom.scale, anchor: .center)
            .offset(zoom.offset)
            .gesture(magnify().simultaneously(with: pan()))
            .highPriorityGesture(doubleTapReset())
            .onChange(of: zoom.scale) { newValue in
                RenderStats.shared.zoomPercent = Int((newValue * 100).rounded())
            }
            .onAppear {
                RenderStats.shared.zoomPercent = Int((zoom.scale * 100).rounded())
            }
        }
    }
    
    private func magnify() -> some Gesture {
        MagnificationGesture()
            .onChanged { v in 
                zoom.scale = v.magnitude
                zoom.clamp()
            }
            .onEnded { _ in zoom.clamp() }
    }
    
    private func pan() -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                zoom.offset = CGSize(
                    width: baseOffset.width + value.translation.width,
                    height: baseOffset.height + value.translation.height
                )
            }
            .onEnded { _ in baseOffset = zoom.offset }
    }
    
    private func doubleTapReset() -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    zoom.reset()
                    baseOffset = .zero
                }
                UISelectionFeedbackGenerator().selectionChanged()
            }
    }
}
