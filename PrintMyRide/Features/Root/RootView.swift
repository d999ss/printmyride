import SwiftUI

struct RootView: View {
    @StateObject private var library = LibraryStore()
    @StateObject private var settings = SettingsStore.shared

    var body: some View {
        Group {
            if library.hasSeenOnboarding {
                TabView {
                    HomeView().tabItem { Label("Home", systemImage: "house.fill") }.accessibilityIdentifier("tab-home")
                    EditorView().tabItem { Label("Create", systemImage: "scribble.variable") }.accessibilityIdentifier("tab-create")
                    GalleryView().tabItem { Label("Gallery", systemImage: "square.grid.2x2.fill") }.accessibilityIdentifier("tab-gallery")
                    SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }.accessibilityIdentifier("tab-settings")
                }
            } else {
                OnboardingView()
            }
        }
        .environmentObject(library)
        .preferredColorScheme(preferredScheme(settings.appearance))   // <- apply
    }

    private func preferredScheme(_ mode: String) -> ColorScheme? {
        switch mode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil    // system
        }
    }
}