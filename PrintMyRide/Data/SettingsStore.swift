import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("appearance") var appearance: String = "dark"   // <- default dark
    @AppStorage("onboardingTheme") var onboardingTheme: String = "studio"
    @AppStorage("onboardingUsePager") var onboardingUsePager: Bool = true
    @AppStorage("useSampleRouteWhenEmpty") var useSampleRouteWhenEmpty: Bool = true
    @AppStorage("alwaysShowControls") var alwaysShowControls: Bool = false
    @AppStorage("showHUD") var showHUD: Bool = false
    @AppStorage("useSampleRoute") var useSampleRoute: Bool = true
    
    static let shared = SettingsStore()
    private init() {}
}