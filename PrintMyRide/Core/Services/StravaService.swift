import SwiftUI
import AuthenticationServices

final class StravaService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = StravaService()
    
    // Configure these before calling connect()
    var clientId: String = ""
    var backendExchange: URL = URL(string:"https://placeholder.invalid/api/strava/exchange")!
    var backendRefresh:  URL = URL(string:"https://placeholder.invalid/api/strava/refresh")!
    var redirectHTTPS: URL = URL(string:"https://placeholder.invalid/oauth/strava/callback")!
    
    func connect() async throws -> StravaTokens {
        #if DEBUG
        print("[Strava] clientId:", clientId, "exchange:", backendExchange, "refresh:", backendRefresh, "redirectHTTPS:", redirectHTTPS)
        #endif
        
        guard !clientId.isEmpty else { throw PMRError.notConnected }

        let redirect = redirectHTTPS.absoluteString
        guard let authURL = URL(string:
            "https://www.strava.com/oauth/authorize?client_id=\(clientId)&response_type=code&redirect_uri=\(redirect)&approval_prompt=auto&scope=read,activity:read_all")
        else { throw PMRError.http }

        let callbackURL: URL = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL,Error>) in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "pmr") { url, err in
                if let u = url { cont.resume(returning: u) }
                else { cont.resume(throwing: err ?? PMRError.cancelled) }
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            _ = session.start()
        }

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "code" })?.value
        else { throw PMRError.badCallback }

        // Exchange code for tokens via your backend
        var req = URLRequest(url: backendExchange)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["code": code])

        let (data, resp) = try await URLSession.shared.data(for: req)
        
        #if DEBUG
        print("[Strava] exchange status:", (resp as? HTTPURLResponse)?.statusCode ?? -1,
              "body:", String(data: data, encoding: .utf8) ?? "")
        #endif
        
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw PMRError.http }

        let toks = try JSONDecoder().decode(StravaTokens.self, from: data)
        // TODO: persist to Keychain if desired
        return toks
    }
    
    // Refresh (optional; wire later)
    func refresh(refreshToken: String) async throws -> StravaTokens {
        var req = URLRequest(url: backendRefresh)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw PMRError.http }
        return try JSONDecoder().decode(StravaTokens.self, from: data)
    }
    
    private func save(_ tokens: StravaTokens) {
        // TODO: Save to Keychain
        UserDefaults.standard.set(tokens.accessToken, forKey: "strava_access_token")
    }
    
    // ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow ?? .init()
    }
}

enum PMRError: Error { 
    case notConnected, cancelled, badCallback, http
}

extension StravaService {
    func configure(clientId: String,
                   exchange: URL,
                   refresh: URL,
                   redirectHTTPS: URL) {
        self.clientId = clientId
        self.backendExchange = exchange
        self.backendRefresh  = refresh
        self.redirectHTTPS = redirectHTTPS
    }
}

extension StravaService {
    struct StravaActivity {
        let id: Int
        let name: String
        let distance: Double
        let movingTime: Double
        let elapsedTime: Double
        let type: String
        let startDate: String
        let summaryPolyline: String?
    }
    
    func fetchActivities() async throws -> [StravaActivity] {
        // TODO: Implement with real tokens
        throw PMRError.notConnected
    }
    
    func buildRoute(from activity: StravaActivity) async throws -> GPXRoute? {
        throw PMRError.notConnected
    }
    
    func fetchStreams(activityId: Int) async throws -> StreamData {
        throw PMRError.notConnected
    }
    
    struct StreamData {
        let latlng: [[Double]]?
        let altitude: [Double]?
        let time: [Double]?
    }
}