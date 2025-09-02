import Foundation
import CoreLocation

final class StravaReal: StravaAPI {
    func isConnected() -> Bool {
        Keychain.get("pmr.strava.token") != nil
    }
    func connect() async throws {
        // No-op here. Real connect is initiated via StravaOAuth.startLogin()
        // and sets token on callback. This method exists for interface parity.
        if !isConnected() { throw NSError(domain: "pmr.strava.notconnected", code: -1) }
    }
    func disconnect() async {
        Keychain.delete("pmr.strava.token")
        Keychain.delete("pmr.strava.refresh")
    }
    func listRecentRides(limit: Int) async throws -> [StravaRide] {
        guard let tokenData = Keychain.get("pmr.strava.token"),
              let token = String(data: tokenData, encoding: .utf8) else { return [] }
        var req = URLRequest(url: URL(string: "https://www.strava.com/api/v3/athlete/activities?per_page=\(limit)")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        let activities = try JSONDecoder().decode([StravaActivityDTO].self, from: data)
        var rides: [StravaRide] = []
        for act in activities {
            var ride = StravaRide(
                id: "\(act.id)",
                name: act.name,
                distanceMeters: act.distance,
                movingTimeSec: act.moving_time,
                startDate: ISO8601DateFormatter().date(from: act.start_date) ?? Date(),
                gpxFilename: nil,
                coords: nil
            )
            // Fetch streams
            let streamsURL = URL(string: "https://www.strava.com/api/v3/activities/\(act.id)/streams?keys=latlng&key_by_type=true")!
            var sreq = URLRequest(url: streamsURL)
            sreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if let (sdata, _) = try? await URLSession.shared.data(for: sreq) {
                if let streams = try? JSONDecoder().decode(StravaStreamsDTO.self, from: sdata),
                   let coords = streams.latlng?.data {
                    ride.coords = coords.compactMap { $0.count == 2 ? CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) : nil }
                }
            }
            rides.append(ride)
        }
        return rides
    }
}