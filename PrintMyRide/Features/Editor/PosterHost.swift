import SwiftUI

struct PosterHost: View {
    let payload: RoutePayload
    let onClose: () -> Void
    
    private func snap(_ v: CGFloat) -> CGFloat {
        let s = UIScreen.main.scale
        return (round(v * s) / s)
    }
    
    private func hostSidePadding(for width: CGFloat) -> CGFloat {
        let raw = max(44, min(72, width * 0.085)) // was min 36, max 64, factor 0.10
        return snap(raw)
    }
    
    private func hostVerticalPadding(for height: CGFloat) -> CGFloat {
        // ~3% of height, min 18pt, max 36pt
        let raw = max(18, min(36, height * 0.03))
        return snap(raw)
    }
    
    var body: some View {
        ZStack { 
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { onClose() } label: {
                        Image(systemName: "xmark").font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(Color.black)

                // Poster area (fills remainder)
                GeometryReader { geo in
                    let side = hostSidePadding(for: geo.size.width)
                    let vpad = hostVerticalPadding(for: geo.size.height)

                    let maxW = max(1, snap(geo.size.width  - side*2))
                    let maxH = max(1, snap(geo.size.height - vpad*2 - 44)) // adjust if bar height differs

                    PosterPreview(
                        design: PosterDesign(),
                        posterTitle: "My Ride",
                        mode: .editor,
                        route: nil,
                        payload: payload
                    )
                    .aspectRatio(18.0/24.0, contentMode: .fit)
                    .frame(maxWidth: maxW, maxHeight: maxH, alignment: .center) // <- no fixed width cap
                    .padding(.horizontal, side)
                    .padding(.vertical, vpad)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // ensure GeometryReader owns all remaining height
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}