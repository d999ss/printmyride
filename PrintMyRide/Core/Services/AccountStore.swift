// PrintMyRide/Services/AccountStore.swift
import Foundation
import Combine
import AuthenticationServices

@MainActor
final class AccountStore: NSObject, ObservableObject {
    static let shared = AccountStore()
    @Published private(set) var account: Account
    private let key = "pmr.account.v1"

    private override init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let acc = try? JSONDecoder().decode(Account.self, from: data) {
            self.account = acc
        } else {
            self.account = .default()
        }
        super.init()
        maintainEntitlements()
        persist() // Ensure initial state is saved
    }

    // MARK: Persistence
    private func persist() {
        var acc = account; acc.updatedAt = Date(); self.account = acc
        if let data = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: Tier & Pro
    func grantPro(until date: Date? = nil) {
        account.tier = .pro
        account.isPro = true
        account.proExpiresAt = date
        persist()
        PMRLog.ui.log("[Account] Pro granted until \(date?.ISO8601Format() ?? "forever", privacy: .public)")
    }

    func revokePro() {
        account.tier = .free
        account.isPro = false
        account.proExpiresAt = nil
        persist()
        PMRLog.ui.log("[Account] Pro revoked")
    }

    private func maintainEntitlements() {
        if let exp = account.proExpiresAt, Date() > exp {
            revokePro()
        }
        if account.isPro && account.tier != .pro { account.tier = .pro; persist() }
    }

    // MARK: Demo / Sign in / Out
    func continueAsGuest() {
        account.tier = .guest
        persist()
        PMRLog.ui.log("[Account] Continuing as guest")
    }

    func signInWithApple(displayName: String?, emailHash: String?) {
        account.tier = account.isPro ? .pro : .free
        account.displayName = displayName
        account.emailHash = emailHash
        persist()
        PMRLog.ui.log("[Account] Signed in with Apple: \(displayName ?? "Unknown", privacy: .public)")
    }

    func signOutAndResetToGuest() {
        account = .default()
        persist()
        PMRLog.ui.log("[Account] Signed out, reset to guest")
    }

    // MARK: Strava link
    func setStravaLinked(_ linked: Bool) {
        account.stravaLinked = linked
        persist()
        PMRLog.ui.log("[Account] Strava \(linked ? "linked" : "unlinked", privacy: .public)")
    }

    // MARK: Destructive
    func deleteAllLocalData() {
        UserDefaults.standard.removeObject(forKey: key)
        account = .default()
        persist()
        PMRLog.ui.log("[Account] All local data deleted")
    }
}