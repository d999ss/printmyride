import Foundation
import SwiftUI
import AuthenticationServices

@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var isStravaConnected = false
    @Published var userId: Int?
    @Published var athleteId: Int?
    @Published var isLoading = false
    
    private let baseURL = URL(string: "http://localhost:3001")!
    
    override init() {
        super.init()
        Task { await checkAuthStatus() }
    }
    
    // MARK: - Email Auth
    
    func startEmailAuth(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let url = baseURL.appendingPathComponent("/auth/email/start")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.emailSendFailed
        }
    }
    
    func checkAuthStatus() async {
        do {
            let url = baseURL.appendingPathComponent("/auth/status")
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Include cookies
            if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
                let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"]
                request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.isAuthenticated = false
                    self.isStravaConnected = false
                    self.userId = nil
                    self.athleteId = nil
                }
                return
            }
            
            let status = try JSONDecoder().decode(AuthStatus.self, from: data)
            
            await MainActor.run {
                self.isAuthenticated = status.authenticated
                self.isStravaConnected = status.strava_connected
                self.userId = status.user_id
                self.athleteId = status.athlete_id
            }
            
        } catch {
            print("❌ Auth status check failed: \(error)")
            await MainActor.run {
                self.isAuthenticated = false
                self.isStravaConnected = false
                self.userId = nil
                self.athleteId = nil
            }
        }
    }
    
    func skipAuth() {
        // Set as authenticated for demo purposes
        isAuthenticated = true
        isStravaConnected = false
        userId = -1  // Demo user ID
        athleteId = nil
    }
    
    func logout() async {
        do {
            let url = baseURL.appendingPathComponent("/auth/logout")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Include cookies
            if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
                let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"]
                request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
            }
            
            let (_, _) = try await URLSession.shared.data(for: request)
            
            // Clear local state
            isAuthenticated = false
            isStravaConnected = false
            userId = nil
            athleteId = nil
            
            // Clear cookies
            if let cookies = HTTPCookieStorage.shared.cookies(for: baseURL) {
                for cookie in cookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
            
        } catch {
            print("❌ Logout failed: \(error)")
        }
    }
    
    // MARK: - Strava Auth
    
    func connectStrava() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let authURL = baseURL.appendingPathComponent("/auth/strava")
        
        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "pmr"
            ) { url, error in
                if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: error ?? AuthError.cancelled)
                }
            }
            
            session.prefersEphemeralWebBrowserSession = false // Keep cookies
            session.presentationContextProvider = self
            session.start()
        }
        
        // Check if successful by looking at URL
        if callbackURL.absoluteString.contains("connected=strava") {
            await checkAuthStatus()
            NotificationCenter.default.post(name: .stravaConnected, object: nil)
        } else if callbackURL.absoluteString.contains("error=") {
            throw AuthError.stravaConnectionFailed
        }
    }
    
    func disconnectStrava() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let url = baseURL.appendingPathComponent("/api/strava/deauthorize")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Include cookies for auth
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"]
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.disconnectFailed
        }
        
        await checkAuthStatus()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Models

struct AuthStatus: Codable {
    let authenticated: Bool
    let user_id: Int?
    let strava_connected: Bool
    let athlete_id: Int?
}

enum AuthError: LocalizedError {
    case emailSendFailed
    case cancelled
    case stravaConnectionFailed
    case disconnectFailed
    
    var errorDescription: String? {
        switch self {
        case .emailSendFailed:
            return "Failed to send login email"
        case .cancelled:
            return "Authentication cancelled"
        case .stravaConnectionFailed:
            return "Failed to connect to Strava"
        case .disconnectFailed:
            return "Failed to disconnect from Strava"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let stravaConnected = Notification.Name("stravaConnected")
    static let stravaDisconnected = Notification.Name("stravaDisconnected")
}