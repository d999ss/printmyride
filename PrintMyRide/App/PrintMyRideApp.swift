import SwiftUI
import UIKit

@main
struct PrintMyRideApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var oauth = StravaOAuth()
    @StateObject private var services = ServiceHub()
    @StateObject private var appearanceManager = AppearanceManager()
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var showOnboarding = false
    @State private var showSplash = true
    
    init() {
        // Configure true Liquid Glass chrome via UIKit
        configureLiquidGlassChrome()
        
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
            print("[Strava] missing STRAVA_* keys in Info.plist - Strava integration disabled")
            #endif
        }
    }

    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !showSplash {
                    // Use new multi-user auth wrapper
                    AuthWrapperView()
                        .environmentObject(appState)
                        .environmentObject(oauth)
                        .environmentObject(services)
                        .environmentObject(appearanceManager)
                        .allowsHitTesting(true)
                        .tint(.accentColor)
                        .onAppear {
                        if ProcessInfo.processInfo.arguments.contains("--PMRTestMode") {
                            UserDefaults.standard.set(true, forKey: "pmr.testMode")
                            UserDefaults.standard.removeObject(forKey: "pmr.hasSeededSamplePoster")
                            let fm = FileManager.default
                            let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            try? fm.removeItem(at: docs.appendingPathComponent("posters_index.json"))
                        }
                            if !hasOnboarded { 
                                AnalyticsService.shared.startOnboardingTimer()
                                showOnboarding = true 
                            }
                        }
                        .onOpenURL { url in
                            // Handle auth callbacks and deep links
                            if url.scheme == "printmyride" {
                                handleDeepLink(url: url)
                            } else {
                                oauth.handleCallback(url: url)
                            }
                        }
                        .fullScreenCover(isPresented: $showOnboarding) {
                            OnboardingCoordinator()
                        }
                }
                
                
                if showSplash {
                    SplashScreen { showSplash = false }
                }
            }
            .preferredColorScheme(appearanceManager.appearanceMode.colorScheme)
            .onChange(of: appearanceManager.appearanceMode) { _ in
                // Force view refresh when appearance mode changes
            }
            .onChange(of: hasOnboarded) { done in
                if done { 
                    showOnboarding = false 
                    AnalyticsService.shared.trackOnboardingCompleted()
                }
            }
        }
    }
    
    // MARK: - Deep Link Handling
    private func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        
        switch components.host {
        case "route":
            handleRouteDeepLink(components: components)
        case "poster":
            handlePosterDeepLink(components: components)
        default:
            print("Unknown deep link: \(url)")
        }
    }
    
    private func handleRouteDeepLink(components: URLComponents) {
        // Extract route parameters
        let queryItems = components.queryItems ?? []
        var routeData: [String: String] = [:]
        
        for item in queryItems {
            routeData[item.name] = item.value
        }
        
        // Show route information or navigate to relevant view
        // For now, just navigate to the main app and let user find the route
        print("Received route deep link with data: \(routeData)")
        
        // You could implement navigation to a specific route here
        // by posting a notification that the main views can observe
        NotificationCenter.default.post(name: .init("PMRRouteDeepLink"), 
                                      object: nil, 
                                      userInfo: routeData)
    }
    
    private func handlePosterDeepLink(components: URLComponents) {
        // Handle poster-specific deep links
        print("Received poster deep link: \(components.url?.absoluteString ?? "")")
        
        NotificationCenter.default.post(name: .init("PMRPosterDeepLink"), 
                                      object: nil, 
                                      userInfo: ["url": components.url?.absoluteString ?? ""])
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

// MARK: - True Liquid Glass Configuration
func configureLiquidGlassChrome() {
    // Navigation Bar - Apple Music style liquid glass
    let nav = UINavigationBarAppearance()
    nav.configureWithDefaultBackground()
    
    // iOS 17+ liquid glass background effect
    if #available(iOS 17.0, *) {
        nav.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
    } else {
        nav.backgroundEffect = UIBlurEffect(style: .systemThickMaterial)
    }
    
    nav.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
    nav.shadowColor = UIColor.separator.withAlphaComponent(0.2)
    nav.titleTextAttributes = [.foregroundColor: UIColor.label]
    nav.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
    UINavigationBar.appearance().standardAppearance = nav
    UINavigationBar.appearance().scrollEdgeAppearance = nav
    UINavigationBar.appearance().compactAppearance = nav
    UINavigationBar.appearance().tintColor = .label
    
    // Hide system tab bar since we're using custom floating glass one
    UITabBar.appearance().isHidden = true
    
    // Toolbar - consistent glass treatment
    let tool = UIToolbarAppearance()
    tool.configureWithTransparentBackground()
    tool.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    tool.backgroundColor = .clear
    UIToolbar.appearance().standardAppearance = tool
    UIToolbar.appearance().compactAppearance = tool
    UIToolbar.appearance().tintColor = .label
}
