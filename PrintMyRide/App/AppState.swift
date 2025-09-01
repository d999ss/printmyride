import Foundation
import Combine
import StoreKit

@MainActor
final class AppState: ObservableObject {
    // Local-only profile bits (expand later)
    @Published var displayName: String = "Rider"
    @Published var units: String = UserDefaults.standard.string(forKey: "pmr.units") ?? "mi"

    // Lifecycle flags
    @Published var hasOnboarded: Bool = UserDefaults.standard.bool(forKey: "pmr.hasOnboarded")
    @Published var lastSeen: Date = Date()
    @Published var posterCount: Int = UserDefaults.standard.integer(forKey: "pmr.posterCount")

    // Subscription (computed from StoreKit)
    @Published var isSubscribed: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        Task { await refreshSubscription() }
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.markSeen() }
            .store(in: &cancellables)
    }

    func markOnboarded() {
        hasOnboarded = true
        UserDefaults.standard.set(true, forKey: "pmr.hasOnboarded")
    }

    func incrementPosterCount() {
        posterCount += 1
        UserDefaults.standard.set(posterCount, forKey: "pmr.posterCount")
    }

    func markSeen() {
        lastSeen = Date()
    }

    func refreshUnitsFromDefaults() {
        units = UserDefaults.standard.string(forKey: "pmr.units") ?? "mi"
    }

    func refreshSubscription() async {
        var active = false
        for await state in Transaction.currentEntitlements {
            if case .verified(let txn) = state, txn.productType == .autoRenewable {
                active = true; break
            }
        }
        await MainActor.run { self.isSubscribed = active }
    }
}