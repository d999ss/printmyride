import Foundation
import SwiftUI

@MainActor
final class MultiUserStravaService: ObservableObject {
    static let shared = MultiUserStravaService()
    
    @Published var activities: [StravaActivity] = []
    @Published var isLoading = false
    @Published var selectedActivities: Set<Int> = []
    
    private let baseURL = URL(string: "http://localhost:3001")!
    
    init() {}
    
    // MARK: - Activities
    
    func fetchActivities(page: Int = 1, perPage: Int = 50) async throws {
        guard AuthService.shared.isAuthenticated && AuthService.shared.isStravaConnected else {
            throw StravaServiceError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/api/activities"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Include auth cookies
        if let cookies = HTTPCookieStorage.shared.cookies(for: baseURL) {
            let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"]
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaServiceError.networkError
        }
        
        if httpResponse.statusCode == 401 {
            throw StravaServiceError.notAuthenticated
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StravaServiceError.apiError(httpResponse.statusCode)
        }
        
        let fetchedActivities = try JSONDecoder().decode([StravaActivity].self, from: data)
        
        if page == 1 {
            activities = fetchedActivities
        } else {
            activities.append(contentsOf: fetchedActivities)
        }
    }
    
    // MARK: - Export
    
    func exportSelectedActivities() async throws -> URL {
        guard !selectedActivities.isEmpty else {
            throw StravaServiceError.noActivitiesSelected
        }
        
        let ids = selectedActivities.map(String.init).joined(separator: ",")
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/api/exports/gpx"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "ids", value: ids)
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        
        // Include auth cookies
        if let cookies = HTTPCookieStorage.shared.cookies(for: baseURL) {
            let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"]
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StravaServiceError.exportFailed
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("strava_export_\(Date().timeIntervalSince1970)")
            .appendingPathExtension("zip")
        
        try data.write(to: tempURL)
        return tempURL
    }
    
    // MARK: - Selection Management
    
    func toggleSelection(for activityId: Int) {
        if selectedActivities.contains(activityId) {
            selectedActivities.remove(activityId)
        } else {
            selectedActivities.insert(activityId)
        }
    }
    
    func selectAll() {
        selectedActivities = Set(activities.map(\.id))
    }
    
    func deselectAll() {
        selectedActivities.removeAll()
    }
    
    var selectionSummary: String {
        if selectedActivities.isEmpty {
            return "No activities selected"
        } else if selectedActivities.count == 1 {
            return "1 activity selected"
        } else {
            return "\(selectedActivities.count) activities selected"
        }
    }
}

// MARK: - Models

struct StravaActivity: Codable, Identifiable {
    let id: Int
    let name: String
    let start: String
    let distance_m: Double
    let moving_time_s: Int
    let elapsed_time_s: Int
    let elev_gain_m: Double?
    let polyline: String?
    let type: String
    let is_private: Bool
    
    var distanceFormatted: String {
        let km = distance_m / 1000
        return String(format: "%.1f km", km)
    }
    
    var movingTimeFormatted: String {
        let hours = moving_time_s / 3600
        let minutes = (moving_time_s % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var startDate: Date? {
        ISO8601DateFormatter().date(from: start)
    }
    
    var startDateFormatted: String {
        guard let date = startDate else { return "Unknown" }
        return DateFormatter.shortDate.string(from: date)
    }
}

enum StravaServiceError: LocalizedError {
    case notAuthenticated
    case networkError
    case apiError(Int)
    case noActivitiesSelected
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in and connect Strava"
        case .networkError:
            return "Network connection failed"
        case .apiError(let code):
            return "API error: \(code)"
        case .noActivitiesSelected:
            return "Please select activities to export"
        case .exportFailed:
            return "Failed to export activities"
        }
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}