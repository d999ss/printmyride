import SwiftUI

struct HeroHeadlineOverlay: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .allowsHitTesting(false)
    }
}