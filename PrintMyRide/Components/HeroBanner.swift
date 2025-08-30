import SwiftUI

struct HeroBanner: View {
    let title: String
    let ctaTitle: String
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Button(action: onTap) {
                Text(ctaTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}