import Foundation
import AuthenticationServices

@MainActor
final class StravaOAuth: NSObject, ASWebAuthenticationPresentationContextProviding, ObservableObject {
    @Published var isConnected: Bool = false

    private let clientID = "YOUR_STRAVA_CLIENT_ID"      // TODO
    private let clientSecret = "YOUR_STRAVA_SECRET"     // TODO (only used server-side ideally)
    private let redirectHTTPS = "https://pmr-auth.vercel.app/strava"
    private let appCallbackScheme = "pmr" // Info.plist
    private var session: ASWebAuthenticationSession?

    // Tokens
    private let tokenKey = "pmr.strava.token"
    private let refreshKey = "pmr.strava.refresh"

    override init() {
        super.init()
        isConnected = Keychain.get(tokenKey) != nil
    }

    func startLogin() {
        let authURL = URL(string:
          "https://www.strava.com/oauth/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectHTTPS)&approval_prompt=auto&scope=read,activity:read_all"
        )!
        session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: appCallbackScheme) { [weak self] url, error in
            guard error == nil, let url else { return }
            self?.handleCallback(url: url)
        }
        session?.presentationContextProvider = self
        session?.prefersEphemeralWebBrowserSession = true
        session?.start()
    }

    func disconnect() {
        Keychain.delete(tokenKey)
        Keychain.delete(refreshKey)
        isConnected = false
    }

    func handleCallback(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              comps.scheme == appCallbackScheme,
              comps.host == "auth",
              comps.path == "/strava",
              let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
        else { return }

        Task { await exchangeCodeForToken(code: code) }
    }

    private func exchangeCodeForToken(code: String) async {
        // Strava token exchange (public doc): POST https://www.strava.com/oauth/token
        var req = URLRequest(url: URL(string: "https://www.strava.com/oauth/token")!)
        req.httpMethod = "POST"
        let params = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        req.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)" }
            .joined(separator: "&")
            .data(using: .utf8)
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                print("Token exchange failed"); return
            }
            struct TokenResp: Decodable { let access_token: String; let refresh_token: String? }
            let tok = try JSONDecoder().decode(TokenResp.self, from: data)
            if let access = tok.access_token.data(using: .utf8) { Keychain.set(access, for: tokenKey) }
            if let refresh = tok.refresh_token?.data(using: .utf8) { Keychain.set(refresh, for: refreshKey) }
            await MainActor.run { self.isConnected = true }
        } catch {
            print("Token exchange error: \(error)")
        }
    }

    // Required by ASWebAuthenticationSession
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Try to return the first key window
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}