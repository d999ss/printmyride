import SwiftUI

@main
struct PrintMyRideApp: App {
    init() {
        UserDefaults.standard.register(defaults: [
            "appearance": "dark",          // "system" | "light" | "dark"
            "onboardingTheme": "studio"    // "studio" (black) | "light"
        ])
    }

    var body: some Scene {
        WindowGroup { RootView() }
    }
}
