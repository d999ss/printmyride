import Foundation

struct StravaTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: TimeInterval // UNIX time
    let athleteId: Int
    
    var isExpired: Bool { 
        Date().timeIntervalSince1970 >= (expiresAt - 60) 
    }
}