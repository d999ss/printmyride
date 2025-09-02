import SwiftUI

struct RootView: View {
    @StateObject private var library = LibraryStore()
    @StateObject private var settings = SettingsStore.shared
    @StateObject private var router = AppRouter()
    @StateObject private var services = ServiceHub()
    @StateObject private var gate = SubscriptionGate()
    @StateObject private var accountStore = AccountStore.shared
    @State private var showPaywall = false
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            // 1) Studio (primary)
            NavigationStack { StudioHubView() }
                .tag(0)
                .tabItem { Label("Studio", systemImage: "scribble.variable") }
            
            // 2) Collections (Favorites)
            FavoritesView()
                .tag(1)
                .tabItem { Label("Collections", systemImage: "heart.fill") }
            
            // 3) Settings
            NavigationStack { SettingsView() }
                .tag(2)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environmentObject(library)
        .environmentObject(router)
        .environmentObject(services)
        .environmentObject(gate)
        .environmentObject(accountStore)
        .preferredColorScheme(preferredScheme(settings.appearance))
        .onReceive(NotificationCenter.default.publisher(for: .pmrRequestPaywall)) { _ in
            if !accountStore.account.isPro { 
                showPaywall = true 
            }
        }
        .sheet(isPresented: $showPaywall) { 
            PaywallPlaceholder() 
        }
        // Build watermark moved to Settings › About
        #if DEBUG
        .overlay(DebugHUD()) // triple-tap to toggle debug panel
        #endif
    }

    private func preferredScheme(_ m: String) -> ColorScheme? { m=="light" ? .light : m=="dark" ? .dark : nil }
}