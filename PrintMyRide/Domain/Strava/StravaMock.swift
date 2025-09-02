import Foundation

final class StravaMock: StravaAPI {
    private var connected = false

    init(preconnected: Bool = false) { self.connected = preconnected }

    func isConnected() -> Bool { connected }

    func connect() async throws { connected = true }

    func disconnect() async { connected = false }

    func listRecentRides(limit: Int) async throws -> [StravaRide] {
        // Two demo rides backed by bundled fixtures (add below)
        return [
            StravaRide(
                id: "demo-park-city",
                name: "Park City Loop",
                distanceMeters: 32456,
                movingTimeSec: 4380,
                startDate: ISO8601DateFormatter().date(from: "2025-08-15T14:00:00Z")!,
                gpxFilename: "Demo_ParkCity.gpx"
            ),
            StravaRide(
                id: "demo-boulder",
                name: "Boulder Canyon Spin",
                distanceMeters: 18540,
                movingTimeSec: 2700,
                startDate: ISO8601DateFormatter().date(from: "2025-07-08T12:00:00Z")!,
                gpxFilename: "Demo_Boulder.gpx"
            )
        ].prefix(limit).map { $0 }
    }
}