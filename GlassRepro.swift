import SwiftUI

struct GlassRepro: View {
  @State private var tab = 0
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  
  var body: some View {
    ZStack(alignment: .bottom) {
      VStack {
        Spacer()
        Rectangle().fill(.pink.opacity(0.25)).frame(height: 220) // must show through
      }
      HStack(spacing: 28) {
        Text("Studio"); Text("Rides"); Text("Profile")
      }
      .padding(.horizontal, 20).padding(.vertical, 12)
      .background(glassSurface)  // <- use the gate from above
      .padding(.horizontal, 12).padding(.bottom, 6)
    }
    .preferredColorScheme(.light)
  }
  
  @ViewBuilder
  private var glassSurface: some View {
    if reduceTransparency {
      // OS forces opaque surfaces; degrade gracefully
      Capsule().fill(.quaternary).overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
    } else if #available(iOS 26, *) {
      Capsule().glassEffect(.regular)
        .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 28, x: 0, y: 6)
    } else if #available(iOS 18, *) {
      Capsule().glassBackgroundEffect(in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 28, x: 0, y: 6)
    } else {
      Capsule().background(.ultraThinMaterial, in: Capsule())
    }
  }
}