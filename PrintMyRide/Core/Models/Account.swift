// PrintMyRide/Models/Account.swift
import Foundation

enum AccountTier: String, Codable { case guest, free, pro }

struct Account: Codable, Equatable {
    var userId: String            // stable UUID
    var tier: AccountTier         // guest/free/pro
    var displayName: String?      // from Apple ID if provided
    var emailHash: String?        // private relay hash if SIWA
    var isPro: Bool               // mirrors tier == .pro
    var proExpiresAt: Date?       // optional duration-based unlock
    var stravaLinked: Bool        // oauth linked
    var createdAt: Date
    var updatedAt: Date
    
    static func `default`() -> Account {
        .init(userId: UUID().uuidString, tier: .guest, displayName: nil, emailHash: nil,
              isPro: false, proExpiresAt: nil, stravaLinked: false,
              createdAt: Date(), updatedAt: Date())
    }
}