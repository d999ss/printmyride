import SwiftUI

struct PosterHost: View {
    let payload: RoutePayload
    let onClose: () -> Void
    
    private func snap(_ v: CGFloat) -> CGFloat {
        let s = UIScreen.main.scale
        return (round(v * s) / s)
    }
    
    private func hostSidePadding(for width: CGFloat) -> CGFloat {
        // ~14% of screen width; min 56pt, max 84pt
        let raw = max(56, min(84, width * 0.14))
        return snap(raw)
    }
    
    private func hostVerticalPadding(for height: CGFloat) -> CGFloat {
        // ~4% of height; min 20pt, max 40pt
        let raw = max(20, min(40, height * 0.04))
        return snap(raw)
    }
    
    var body: some View {
        ZStack { 
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    Button { onClose() } label: {
                        Image(systemName: "xmark").font(.system(size: 18, weight: .semibold))
                    }.foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(Color.black)

                // Centered 18×24 poster with outer gutters
                GeometryReader { geo in
                    let side = hostSidePadding(for: geo.size.width)
                    let vpad = hostVerticalPadding(for: geo.size.height)
                    
                    let hostW = snap(geo.size.width  - side*2)
                    let hostH = snap(geo.size.height - vpad*2)
                    
                    // 🔎 DEBUG: overlay the numbers
                    let _ = print("[PosterHost] geo:", geo.size, "side:", side, "vpad:", vpad, "hostW:", hostW, "hostH:", hostH)
                    
                    VStack(spacing: 0) {
                        PosterPreview(design: PosterDesign(),
                                      posterTitle: "My Ride",
                                      mode: .editor,
                                      route: nil,
                                      payload: payload)
                            .frame(width: hostW, height: hostH)
                            .clipped()
                            .overlay(alignment: .topLeading) {
                                #if DEBUG
                                Text(String(format:"hostW: %.1f\nhostH: %.1f", hostW, hostH))
                                    .font(.caption2).foregroundStyle(.red).padding(6)
                                #endif
                            }
                    }
                    .padding(.horizontal, side)
                    .padding(.vertical, vpad)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}