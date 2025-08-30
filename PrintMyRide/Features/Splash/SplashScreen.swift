import SwiftUI

struct SplashScreen: View {
    let done: () -> Void
    @State private var opacity: CGFloat = 0.0
    @State private var scale: CGFloat = 0.92

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PMRLogoView()
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .task {
            // subtle entrance
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1.0
                scale = 1.0
            }
            // hold the logo on screen ~2.4s after the intro anim (~3s total)
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            // fade out
            withAnimation(.easeIn(duration: 0.35)) { opacity = 0.0 }
            try? await Task.sleep(nanoseconds: 350_000_000)
            done()
        }
        .accessibilityHidden(true) // splash is decorative
    }
}