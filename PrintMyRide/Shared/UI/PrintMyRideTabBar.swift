import SwiftUI

// MARK: - Tokens tuned to Apple's look
private enum Glass {
  static let hPadding: CGFloat = 20
  static let vPadding: CGFloat = 12
  static let spacing:  CGFloat = 28
  static let shadowOpacityLight: CGFloat = 0.15
  static let shadowRadius: CGFloat = 28
  static let shadowYOffset: CGFloat = 6
  static let activeOpacity: CGFloat = 1.0
  static let inactiveOpacity: CGFloat = 0.70
  static let iconSize: CGFloat = 22
}

struct PrintMyRideTabBar: View {
  @Binding var selection: Int
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    HStack(spacing: 28) {
      item("Studio",  "photo.on.rectangle", 0)
      item("Rides",   "bicycle",            1)
      item("Profile", "person",             2)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(
      ZStack { glassSurface; sheen.mask(Capsule()) }
    )
    // NO container opacity here - it kills glass vibrancy
    .padding(.horizontal, 8)
  }

  @ViewBuilder
  private func item(_ title: String, _ symbol: String, _ idx: Int) -> some View {
    let active = selection == idx
    Button { selection = idx } label: {
      VStack(spacing: 6) {
        Image(systemName: active ? filledSymbol(for: symbol) : symbol)
          .font(.system(size: 22, weight: .semibold))
          // Ideally: .foregroundStyle(.vibrancyGroup(.primary))
          // But iOS 18 doesn't have it, so use standard label color
        Text(title).font(.footnote.weight(active ? .semibold : .regular))
      }
      .frame(minWidth: 80, minHeight: 50)  // Increased for better hit area
      .contentShape(Rectangle())           // Ensure entire frame is tappable
    }
    .buttonStyle(.plain)
    .opacity(active ? 1.0 : 0.7)     // content-only, not container
    // NO .foregroundColor - it kills vibrancy
  }

  @ViewBuilder
  private var glassSurface: some View {
    if reduceTransparency {
      Capsule()
        .fill(.quaternary)
        .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
    } else {
      Capsule()
        .fill(.ultraThinMaterial)  // Single glass surface
        .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 40, x: 0, y: 8)  // Wide, soft shadow for float
    }
  }
  
  private func filledSymbol(for symbol: String) -> String {
    switch symbol {
    case "bicycle":
      return "bicycle.circle.fill"
    case "photo.on.rectangle":
      return "photo.on.rectangle.fill" 
    case "person":
      return "person.fill"
    default:
      return "\(symbol).fill"
    }
  }
  
  private var sheen: some View {
    LinearGradient(stops: [
      .init(color: .white.opacity(0.06), location: 0.0),
      .init(color: .clear,               location: 0.55),
      .init(color: .white.opacity(0.04), location: 1.0)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)
    .blendMode(.screen)
    .allowsHitTesting(false)
    .decorative()  // Mark as decorative for TapDoctor
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

