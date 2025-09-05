import SwiftUI

struct PrintMyRideTabBar: View {
  @Binding var selection: Int

  var body: some View {
    HStack(spacing: 28) {
      item("Studio",  "rectangle.portrait.on.rectangle.portrait", 0)
      item("Rides",   "point.topleft.down.curvedto.point.bottomright.up",            1)
      item("Profile", "person",             2)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(LiquidGlassCapsule())
    .liquidGlassCapsule()
    .padding(.horizontal, 8)
  }

  @ViewBuilder
  private func item(_ title: String, _ symbol: String, _ idx: Int) -> some View {
    let active = selection == idx
    Button { selection = idx } label: {
      VStack(spacing: 6) {
        Image(systemName: active ? filledSymbol(for: symbol) : symbol)
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(.primary)
        Text(title)
          .font(.footnote.weight(active ? .semibold : .regular))
          .foregroundStyle(.primary)
      }
      .frame(minWidth: 88, minHeight: 56)  // Ensure 44pt minimum tap target
      .contentShape(Rectangle())           // Ensure entire frame is tappable
    }
    .buttonStyle(.plain)
    .opacity(active ? 1.0 : 0.7)     // content-only, not container
    // NO .foregroundColor - it kills vibrancy
  }

  private func filledSymbol(for symbol: String) -> String {
    switch symbol {
    case "bicycle":
      return "bicycle"  // No .fill version exists, keep original
    case "photo.on.rectangle":
      return "photo.on.rectangle.fill" 
    case "person":
      return "person.fill"
    default:
      return "\(symbol).fill"
    }
  }
  
}

// MARK: - Motion polish (optional, subtle specular) - DISABLED TO PREVENT ISOLATION
// extension View {
//   func specularSheen(in shape: some Shape) -> some View {
//     self.overlay(
//       LinearGradient(stops: [
//         .init(color: .white.opacity(0.06), location: 0.0),
//         .init(color: .clear,               location: 0.5),
//         .init(color: .white.opacity(0.04), location: 1.0)
//       ], startPoint: .topLeading, endPoint: .bottomTrailing)
//         .mask(shape)  // removed .blendMode(.screen) - isolator
//         .allowsHitTesting(false)
//         .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: UUID())
//     )
//   }
// }

