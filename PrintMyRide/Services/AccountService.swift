import Foundation

struct AccountProfile: Codable, Equatable {
    var id: String = "local"       // replace with server ID later
    var email: String? = nil
    var displayName: String? = nil
    var avatarURL: URL? = nil
}

protocol AccountService {
    func currentProfile() async throws -> AccountProfile
    func updateProfile(_ profile: AccountProfile) async throws
    func signInWithApple() async throws  // stub for future
    func signOut() async throws
}

final class LocalAccountService: AccountService {
    private let key = "pmr.local.profile.json"
    private var url: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(key) }

    func currentProfile() async throws -> AccountProfile {
        if let data = try? Data(contentsOf: url),
           let p = try? JSONDecoder().decode(AccountProfile.self, from: data) { return p }
        return AccountProfile()
    }

    func updateProfile(_ profile: AccountProfile) async throws {
        let data = try JSONEncoder().encode(profile)
        try data.write(to: url, options: .atomic)
    }

    func signInWithApple() async throws { /* no-op V1 */ }
    func signOut() async throws { try? FileManager.default.removeItem(at: url) }
}