import Foundation

@MainActor
final class StravaAuthManager: ObservableObject {
    @Published private(set) var isConnected: Bool = false
    private let tokenKey = "pmr.strava.token"

    init() {
        isConnected = Keychain.get(tokenKey) != nil
    }

    func connect(token: String) {
        guard let data = token.data(using: .utf8) else { return }
        if Keychain.set(data, for: tokenKey) {
            isConnected = true
        }
    }

    func disconnect() {
        Keychain.delete(tokenKey)
        isConnected = false
    }

    // Placeholder for actual OAuth flow. V1 can hand off to your existing Strava login.
    func beginOAuth() {
        // TODO: implement real flow; on success call connect(token:)
        print("Start Strava OAuth")
    }
}