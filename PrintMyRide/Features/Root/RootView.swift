import SwiftUI

struct RootView: View {
    @StateObject private var library = LibraryStore()
    @StateObject private var settings = SettingsStore.shared
    @StateObject private var router = AppRouter()
    @StateObject private var services = ServiceHub()
    @StateObject private var gate = SubscriptionGate()
    @StateObject private var accountStore = AccountStore.shared
    @State private var showPaywall = false
    @State private var hideTabBar = false
    
    var body: some View {
        NavigationStack {
            Group {
                switch router.selectedTab {
                case 0:
                    StudioHubView()
                case 1:
                    RidesListView()
                case 2:
                    SettingsView()
                default:
                    StudioHubView()
                }
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)   // no group plate
            .listRowBackground(Color.clear)
            .background(.clear)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !hideTabBar {
                PrintMyRideTabBar(selection: $router.selectedTab)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                    .background(.clear)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Optional: fill the empty bottom area with clear content so glass samples something
        .background(Color.clear.ignoresSafeArea(edges: .bottom))
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .environmentObject(library)
        .environmentObject(router)
        .environmentObject(services)
        .environmentObject(gate)
        .environmentObject(accountStore)
        .preferredColorScheme(.light) // Force light mode for Apple Glass
        .onReceive(NotificationCenter.default.publisher(for: .pmrHideTabBar)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                hideTabBar = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pmrShowTabBar)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                hideTabBar = false
            }
        }
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

