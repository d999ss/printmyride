import Foundation
import StoreKit
@testable import PrintMyRide

// MARK: - Mock Strava Service

final class MockStravaService {
    var shouldSucceed = true
    var mockActivities: [StravaActivity] = []
    
    func fetchActivities() async throws -> [StravaActivity] {
        guard shouldSucceed else {
            throw NSError(domain: "MockStrava", code: -1)
        }
        return mockActivities
    }
}

// MARK: - Mock StoreKit Service

@available(iOS 15.0, *)
final class MockSubscriptionService {
    var isSubscribed = false
    var products: [Product] = []
    
    func checkSubscription() async -> Bool {
        return isSubscribed
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        guard isSubscribed else {
            throw NSError(domain: "MockStore", code: -1)
        }
        return nil // Mock transaction
    }
}

// MARK: - Stub Strava Activity

struct StravaActivity: Codable {
    let id: Int
    let name: String
    let distance: Double
    let movingTime: Int
    let startDate: String
}

// MARK: - Test Fixtures

enum TestFixtures {
    static let sampleGPX = """
    <?xml version="1.0" encoding="UTF-8"?>
    <gpx version="1.1">
        <trk>
            <name>Test Route</name>
            <trkseg>
                <trkpt lat="40.7128" lon="-74.0060">
                    <ele>10</ele>
                </trkpt>
                <trkpt lat="40.7130" lon="-74.0062">
                    <ele>12</ele>
                </trkpt>
            </trkseg>
        </trk>
    </gpx>
    """
    
    static let sampleActivity = StravaActivity(
        id: 12345,
        name: "Morning Ride",
        distance: 25000,
        movingTime: 3600,
        startDate: "2024-01-15T08:00:00Z"
    )
}