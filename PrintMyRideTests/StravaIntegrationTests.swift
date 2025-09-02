import XCTest
import CoreLocation
@testable import PrintMyRide

final class StravaIntegrationTests: XCTestCase {
    
    private var stravaService: StravaService!
    private let testAccessToken = ProcessInfo.processInfo.environment["STRAVA_ACCESS_TOKEN"] ?? ""
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Skip tests if no access token provided
        guard !testAccessToken.isEmpty else {
            throw XCTSkip("Set STRAVA_ACCESS_TOKEN environment variable to run Strava integration tests")
        }
        
        stravaService = StravaService()
        stravaService.setAccessToken(testAccessToken)
    }
    
    // MARK: - Authentication Tests
    
    func testStravaAuthentication() async throws {
        let athlete = try await stravaService.fetchAthlete()
        
        XCTAssertNotNil(athlete.id)
        XCTAssertNotNil(athlete.firstname)
        XCTAssertTrue(athlete.id > 0, "Athlete ID should be valid")
        
        print("✅ Authenticated as: \(athlete.firstname ?? "Unknown") \(athlete.lastname ?? "")")
    }
    
    // MARK: - Activity Import Tests
    
    func testFetchRecentActivities() async throws {
        let activities = try await stravaService.fetchRecentActivities(limit: 10)
        
        XCTAssertFalse(activities.isEmpty, "Should have at least some activities")
        XCTAssertLessThanOrEqual(activities.count, 10, "Should respect limit parameter")
        
        // Test activity structure
        if let firstActivity = activities.first {
            XCTAssertNotNil(firstActivity.id)
            XCTAssertNotNil(firstActivity.name)
            XCTAssertNotNil(firstActivity.startDate)
            XCTAssertGreaterThan(firstActivity.distance, 0, "Distance should be positive")
            
            print("✅ Found activity: \(firstActivity.name) - \(firstActivity.distance/1000)km")
        }
    }
    
    func testActivityWithPolylineDecoding() async throws {
        let activities = try await stravaService.fetchRecentActivities(limit: 5)
        
        // Find activity with route data
        guard let activityWithRoute = activities.first(where: { $0.map?.summaryPolyline != nil && !$0.map!.summaryPolyline!.isEmpty }) else {
            throw XCTSkip("No activities with route data found")
        }
        
        let polyline = activityWithRoute.map!.summaryPolyline!
        let coordinates = PolylineDecoder.decode(polyline)
        
        XCTAssertGreaterThan(coordinates.count, 10, "Route should have meaningful coordinate count")
        
        // Validate coordinate bounds (reasonable lat/lng values)
        for coord in coordinates {
            XCTAssertTrue(abs(coord.latitude) <= 90, "Latitude should be valid")
            XCTAssertTrue(abs(coord.longitude) <= 180, "Longitude should be valid")
        }
        
        print("✅ Decoded polyline: \(coordinates.count) coordinates from \(polyline.prefix(50))...")
    }
    
    func testActivityStreamsForHighResPosters() async throws {
        let activities = try await stravaService.fetchRecentActivities(limit: 5)
        
        guard let testActivity = activities.first else {
            throw XCTSkip("No activities available for streams test")
        }
        
        do {
            let streams = try await stravaService.fetchActivityStreams(activityId: testActivity.id, streamTypes: ["latlng", "distance", "altitude"])
            
            XCTAssertNotNil(streams.latlng, "Should have coordinate stream")
            if let coordinates = streams.latlng {
                XCTAssertGreaterThan(coordinates.count, 0, "Coordinate stream should not be empty")
                
                // Test first and last coordinates are different (actual route)
                if coordinates.count > 1 {
                    let first = coordinates.first!
                    let last = coordinates.last!
                    let distance = CLLocation(latitude: first.latitude, longitude: first.longitude)
                        .distance(from: CLLocation(latitude: last.latitude, longitude: last.longitude))
                    XCTAssertGreaterThan(distance, 10, "Route should have meaningful distance between start/end")
                }
            }
            
            print("✅ Streams data: \(streams.latlng?.count ?? 0) coordinates")
            
        } catch StravaError.streamsNotAvailable {
            print("⚠️ Streams not available for this activity (may be synthetic)")
        } catch {
            throw error
        }
    }
    
    // MARK: - End-to-End Poster Generation
    
    func testStravaActivityToPosterGeneration() async throws {
        let activities = try await stravaService.fetchRecentActivities(limit: 3)
        
        guard let activity = activities.first(where: { $0.map?.summaryPolyline != nil }) else {
            throw XCTSkip("No activities with route data for poster generation")
        }
        
        // Decode polyline to coordinates
        let polyline = activity.map!.summaryPolyline!
        let coordinates = PolylineDecoder.decode(polyline)
        
        XCTAssertGreaterThan(coordinates.count, 5, "Need sufficient coordinates for poster")
        
        // Test poster generation
        let posterSize = CGSize(width: 1200, height: 1600)
        let poster = await LegacyRendererBridge.renderImage(
            coords: coordinates,
            size: posterSize,
            title: activity.name,
            stats: [
                "Distance  \(String(format: "%.1f", activity.distance/1000)) km",
                "Time      \(formatDuration(activity.elapsedTime))",
                "Date      \(formatDate(activity.startDate))"
            ]
        )
        
        XCTAssertNotNil(poster, "Poster should be generated successfully")
        
        if let poster = poster {
            XCTAssertEqual(poster.size.width, posterSize.width, accuracy: 1)
            XCTAssertEqual(poster.size.height, posterSize.height, accuracy: 1)
            
            // Save for manual inspection in debug builds
            #if DEBUG
            if let data = poster.jpegData(compressionQuality: 0.8) {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("strava_test_poster.jpg")
                try? data.write(to: url)
                print("✅ Test poster saved to: \(url.path)")
            }
            #endif
        }
        
        print("✅ End-to-end: Strava activity → \(coordinates.count) coords → poster generated")
    }
    
    // MARK: - Rate Limiting and Error Handling
    
    func testRateLimitHandling() async throws {
        // Test that we handle rate limits gracefully
        var requestCount = 0
        
        do {
            // Make multiple rapid requests to test rate limiting
            for _ in 0..<5 {
                _ = try await stravaService.fetchRecentActivities(limit: 1)
                requestCount += 1
                
                // Small delay to avoid immediate rate limiting
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            print("✅ Made \(requestCount) requests without rate limiting")
            
        } catch StravaError.rateLimitExceeded(let retryAfter) {
            print("⚠️ Rate limited after \(requestCount) requests, retry after: \(retryAfter)")
            XCTAssertGreaterThan(retryAfter, 0, "Retry after should be positive")
            
        } catch {
            throw error
        }
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanupTestActivities() async throws {
        // This test helps clean up any test activities created during development
        let activities = try await stravaService.fetchRecentActivities(limit: 20)
        
        let testActivities = activities.filter { 
            $0.name.contains("PMR Test") || $0.description?.contains("Test activity for PrintMyRide") == true
        }
        
        print("Found \(testActivities.count) test activities to potentially clean up:")
        for activity in testActivities {
            print("  - \(activity.name) (ID: \(activity.id))")
        }
        
        // Note: Uncomment below to actually delete test activities
        // for activity in testActivities {
        //     try await stravaService.deleteActivity(activityId: activity.id)
        //     print("🗑️ Deleted test activity: \(activity.name)")
        // }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Mock Strava Service for Testing

class StravaService {
    private var accessToken: String = ""
    
    func setAccessToken(_ token: String) {
        accessToken = token
    }
    
    func fetchAthlete() async throws -> StravaAthlete {
        let url = URL(string: "https://www.strava.com/api/v3/athlete")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init) ?? 900
            throw StravaError.rateLimitExceeded(retryAfter: retryAfter)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StravaError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(StravaAthlete.self, from: data)
    }
    
    func fetchRecentActivities(limit: Int) async throws -> [StravaActivity] {
        let url = URL(string: "https://www.strava.com/api/v3/athlete/activities?per_page=\(limit)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init) ?? 900
            throw StravaError.rateLimitExceeded(retryAfter: retryAfter)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StravaError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([StravaActivity].self, from: data)
    }
    
    func fetchActivityStreams(activityId: Int, streamTypes: [String]) async throws -> StravaStreams {
        let streamTypesParam = streamTypes.joined(separator: ",")
        let url = URL(string: "https://www.strava.com/api/v3/activities/\(activityId)/streams?keys=\(streamTypesParam)&key_by_type=true")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init) ?? 900
            throw StravaError.rateLimitExceeded(retryAfter: retryAfter)
        }
        
        if httpResponse.statusCode == 404 {
            throw StravaError.streamsNotAvailable
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StravaError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(StravaStreams.self, from: data)
    }
}

// MARK: - Strava Data Models

struct StravaAthlete: Codable {
    let id: Int
    let firstname: String?
    let lastname: String?
}

struct StravaActivity: Codable {
    let id: Int
    let name: String
    let distance: Double
    let elapsedTime: Int
    let startDate: Date
    let map: StravaMap?
    let description: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, distance, map, description
        case elapsedTime = "elapsed_time"
        case startDate = "start_date"
    }
}

struct StravaMap: Codable {
    let summaryPolyline: String?
    
    private enum CodingKeys: String, CodingKey {
        case summaryPolyline = "summary_polyline"
    }
}

struct StravaStreams: Codable {
    let latlng: [CLLocationCoordinate2D]?
    let distance: [Double]?
    let altitude: [Double]?
}

extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let latitude = try container.decode(Double.self)
        let longitude = try container.decode(Double.self)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }
}

enum StravaError: Error {
    case invalidResponse
    case httpError(Int)
    case rateLimitExceeded(retryAfter: Int)
    case streamsNotAvailable
}

// MARK: - Polyline Decoder

class PolylineDecoder {
    static func decode(_ polyline: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var lat = 0.0, lng = 0.0
        var index = polyline.startIndex
        
        while index < polyline.endIndex {
            var shift = 0, result = 0
            
            // Decode latitude
            repeat {
                let byte = Int(polyline[index].asciiValue! - 63)
                index = polyline.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while result & 1 != 0 && index < polyline.endIndex
            
            lat += Double((result & 1) != 0 ? ~(result >> 1) : (result >> 1)) / 1e5
            
            shift = 0
            result = 0
            
            // Decode longitude
            repeat {
                let byte = Int(polyline[index].asciiValue! - 63)
                index = polyline.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while result & 1 != 0 && index < polyline.endIndex
            
            lng += Double((result & 1) != 0 ? ~(result >> 1) : (result >> 1)) / 1e5
            
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
        
        return coordinates
    }
}