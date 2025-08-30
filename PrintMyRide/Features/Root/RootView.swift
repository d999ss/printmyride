import SwiftUI

struct RootView: View {
    @StateObject private var library = LibraryStore()
    @StateObject private var settings = SettingsStore.shared
    @StateObject private var router = AppRouter()
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView() .tag(0).tabItem { Label("Home",    systemImage: "house.fill") }
            EditorV2() .tag(1).tabItem { Label("Create",  systemImage: "scribble.variable") }
            GalleryView().tag(2).tabItem { Label("Gallery",systemImage: "square.grid.2x2.fill") }
            SettingsView().tag(3).tabItem { Label("Settings",systemImage: "gearshape.fill") }
        }
        .environmentObject(library)
        .environmentObject(router)
        .preferredColorScheme(preferredScheme(settings.appearance))
    }

    private func preferredScheme(_ m: String) -> ColorScheme? { m=="light" ? .light : m=="dark" ? .dark : nil }
}