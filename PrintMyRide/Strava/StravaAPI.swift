import Foundation
import CoreLocation

/// Domain model used by the app. Not Codable on purpose.
struct StravaRide: Identifiable, Equatable {
    let id: String
    let name: String
    let distanceMeters: Double
    let movingTimeSec: Int
    let startDate: Date
    let gpxFilename: String? // bundled demo GPX for mock/demo
    var coords: [CLLocationCoordinate2D]? = nil
    
    static func == (lhs: StravaRide, rhs: StravaRide) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.distanceMeters == rhs.distanceMeters && lhs.movingTimeSec == rhs.movingTimeSec && lhs.startDate == rhs.startDate
    }
    
    var gpxData: String? {
        guard let filename = gpxFilename,
              let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".gpx", with: ""), withExtension: "gpx"),
              let data = try? Data(contentsOf: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

protocol StravaAPI {
    func isConnected() -> Bool
    func connect() async throws
    func disconnect() async
    func listRecentRides(limit: Int) async throws -> [StravaRide]
}