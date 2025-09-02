import Foundation

@MainActor
final class SubscriptionGate: ObservableObject {
    @Published var isSubscribed: Bool = false
    
    init() {
        // For V1 demo, default to false to test paywall flow
        // Later: check actual StoreKit subscription status
        isSubscribed = UserDefaults.standard.bool(forKey: "pmr.demo.subscribed")
    }
    
    func toggleDemo() {
        isSubscribed.toggle()
        UserDefaults.standard.set(isSubscribed, forKey: "pmr.demo.subscribed")
    }
    
    func refresh() async {
        // For demo: check UserDefaults
        // Later: check StoreKit subscription status
        isSubscribed = UserDefaults.standard.bool(forKey: "pmr.demo.subscribed")
    }
}