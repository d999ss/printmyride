import Foundation

@MainActor
final class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func track(_ event: String, properties: [String: Any] = [:]) {
        #if DEBUG
        print("📊 Analytics: \(event)")
        if !properties.isEmpty {
            print("   Properties: \(properties)")
        }
        #endif
        
        // In production, this would integrate with your analytics provider
        // Examples: Amplitude, Mixpanel, Firebase Analytics, etc.
        
        // For now, store locally for debugging
        UserDefaults.standard.set(Date(), forKey: "last_analytics_event")
        UserDefaults.standard.set(event, forKey: "last_event_name")
    }
    
    // Convenience methods for common events
    func trackOnboardingStarted() {
        track("onboarding_shown")
    }
    
    func trackConnectionAttempt(provider: String) {
        track("connect_clicked", properties: ["provider": provider])
    }
    
    func trackOAuthResult(provider: String, success: Bool, error: String? = nil) {
        var properties: [String: Any] = ["provider": provider]
        if let error = error {
            properties["error"] = error
        }
        
        track(success ? "oauth_success" : "oauth_fail", properties: properties)
    }
    
    func trackPermissionPrompted(_ permission: String) {
        track("permissions_prompted", properties: ["permission": permission])
    }
    
    func trackRidesImported(count: Int) {
        track("rides_imported", properties: ["count": count])
    }
    
    func trackPosterGenerated(rideId: String, renderTime: Int) {
        track("poster_generated", properties: [
            "ride_id": rideId,
            "ms_render": renderTime
        ])
    }
    
    func trackPosterSaved(destination: String) {
        track("poster_saved", properties: ["destination": destination])
    }
    
    func trackOnboardingCompleted() {
        track("onboarding_completed")
        
        // Calculate time-to-value
        if let startTime = UserDefaults.standard.object(forKey: "onboarding_start_time") as? Date {
            let timeToValue = Date().timeIntervalSince(startTime)
            track("time_to_value", properties: ["seconds": Int(timeToValue)])
        }
    }
    
    func startOnboardingTimer() {
        UserDefaults.standard.set(Date(), forKey: "onboarding_start_time")
    }
}