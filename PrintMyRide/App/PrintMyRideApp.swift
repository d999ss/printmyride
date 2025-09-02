import SwiftUI
import UIKit

@main
struct PrintMyRideApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var oauth = StravaOAuth()
    @StateObject private var services = ServiceHub()
    @AppStorage("pmr.hasOnboarded") private var hasOnboarded: Bool = true
    @State private var showOnboarding = false
    @State private var showSplash = true
    
    init() {
        // Initialize poster snapshot system
        AppBootstrap.run()
        
        // Defaults: dark + studio + show onboarding for new users
        UserDefaults.standard.register(defaults: [
            "appearance": "dark",
            "onboardingTheme": "studio", 
            "useSampleRouteWhenEmpty": true,
            "hasSeenOnboarding": false,         // ← show onboarding for new users (per spec)
            "onboardingVersion": 1
        ])

        // One-time migration for testers who already have hasSeenOnboarding = false
        let u = UserDefaults.standard
        if u.integer(forKey: "onboardingVersion") < 1 {
            u.set(true, forKey: "hasSeenOnboarding")       // force skip
            u.set(1,    forKey: "onboardingVersion")
        }
        
        // Debug: Log what's actually loaded
        #if DEBUG
        print("[Info] STRAVA_CLIENT_ID:",
              Bundle.main.object(forInfoDictionaryKey: "STRAVA_CLIENT_ID") ?? "nil")
        print("[Info] EXCHANGE:",
              Bundle.main.object(forInfoDictionaryKey: "STRAVA_BACKEND_EXCHANGE") ?? "nil")
        print("[Info] REFRESH:",
              Bundle.main.object(forInfoDictionaryKey: "STRAVA_BACKEND_REFRESH") ?? "nil")
        #endif
        
        // Load Strava config from Info.plist
        if let cfg = StravaConfig.load() {
            StravaService.shared.configure(clientId: cfg.clientId,
                                           exchange: cfg.exchangeURL,
                                           refresh:  cfg.refreshURL,
                                           redirectHTTPS: cfg.redirectHTTPS)
            #if DEBUG
            print("[Strava] configured with clientId:", cfg.clientId)
            #endif
        } else {
            #if DEBUG
            print("[Strava] missing STRAVA_* keys in Info.plist")
            // Fallback: set values directly to test OAuth pipeline
            // TODO: Replace <YOUR_WORKER> with actual worker domain
            StravaService.shared.configure(
                clientId: "173748",
                exchange: URL(string:"https://your-worker.workers.dev/api/strava/exchange")!,
                refresh:  URL(string:"https://your-worker.workers.dev/api/strava/refresh")!,
                redirectHTTPS: URL(string:"https://printmyride.app/oauth/strava/callback")!
            )
            #endif
        }
        
        // Configure monochrome tab bar appearance
        let tab = UITabBarAppearance(); tab.configureWithOpaqueBackground()
        tab.backgroundColor = .black; tab.shadowColor = .clear
        func style(_ a: UITabBarItemAppearance) {
            a.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
            a.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
            a.normal.iconColor = .secondaryLabel
            a.selected.iconColor = .label
        }
        style(tab.stackedLayoutAppearance)
        style(tab.inlineLayoutAppearance)
        style(tab.compactInlineLayoutAppearance)
        UITabBar.appearance().standardAppearance = tab
        if #available(iOS 15, *) { UITabBar.appearance().scrollEdgeAppearance = tab }
        UITabBar.appearance().tintColor = .label
        UITabBar.appearance().unselectedItemTintColor = .secondaryLabel
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !showSplash {
                    OnboardingGate()                   // your main app with onboarding gate
                        .environmentObject(appState)
                        .environmentObject(oauth)
                        .environmentObject(services)
                        .allowsHitTesting(true)        // force-enable interactions
                        // System-native global polish
                        .tint(.orange)  // Brand accent color applied globally
                        .onAppear {
                        if ProcessInfo.processInfo.arguments.contains("--PMRTestMode") {
                            UserDefaults.standard.set(true, forKey: "pmr.testMode")
                            // Ensure deterministic first-run: clear local poster data and seeded flag
                            UserDefaults.standard.removeObject(forKey: "pmr.hasSeededSamplePoster")
                            let fm = FileManager.default
                            let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            try? fm.removeItem(at: docs.appendingPathComponent("posters_index.json"))
                        }
                            if !hasOnboarded { showOnboarding = true }
                        }
                        .onOpenURL { url in
                            // Forward to OAuth handler; it checks scheme/host/path
                            oauth.handleCallback(url: url)
                        }
                        // Overlay-based onboarding that doesn't block touch events
                        .overlay(alignment: .center) {
                            if showOnboarding {
                                SimpleOnboardingView {
                                    withAnimation(.easeInOut) {
                                        hasOnboarded = true
                                        showOnboarding = false
                                    }
                                }
                                .transition(.opacity.combined(with: .scale))
                                .zIndex(1000)
                            }
                        }
                }
                
                // Health overlay for debugging (hidden automatically in focus modes)
                if !showSplash && !ProcessInfo.processInfo.arguments.contains("--hideDebugPills") {
                    VStack {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("🟢 Touch OK")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.green.opacity(0.8))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        print("[Health] Touch test successful!")
                                    }
                                    .allowsHitTesting(true)
                                
                                Text("Nav: \(hasOnboarded ? "Ready" : "Blocked")")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(hasOnboarded ? .green.opacity(0.8) : .red.opacity(0.8))
                                    .cornerRadius(8)
                            }
                            .padding(.trailing, 12)
                            .padding(.top, 60)
                        }
                        Spacer()
                    }
                    .allowsHitTesting(false) // Container doesn't block touches
                    .zIndex(1500) // Lower than focus mode overlays
                }
                
                if showSplash {
                    SplashScreen { showSplash = false }
                }
            }
            .onChange(of: hasOnboarded) { done in
                if done { showOnboarding = false }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// Simple loader for plist values
struct StravaConfig {
    let clientId: String
    let exchangeURL: URL
    let refreshURL: URL
    let redirectHTTPS: URL

    static func load() -> StravaConfig? {
        func s(_ k: String) -> String? { Bundle.main.object(forInfoDictionaryKey: k) as? String }
        guard
            let id = s("STRAVA_CLIENT_ID"), !id.isEmpty,
            let ex = s("STRAVA_BACKEND_EXCHANGE"), let exURL = URL(string: ex),
            let rf = s("STRAVA_BACKEND_REFRESH"),  let rfURL = URL(string: rf),
            let rd = s("STRAVA_REDIRECT_HTTPS"), let rdURL = URL(string: rd)
        else { return nil }
        return .init(clientId: id, exchangeURL: exURL, refreshURL: rfURL, redirectHTTPS: rdURL)
    }
}
