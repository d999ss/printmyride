import SwiftUI
import HealthKit
import CoreLocation

enum OnboardingStep: Hashable { 
    case welcome, connect, permissions, importing, posterPreview, tips, done 
}

@MainActor
final class OnboardingModel: ObservableObject {
    @Published var step: OnboardingStep = .welcome
    @Published var rides: [Ride] = []
    @Published var poster: Poster?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let analytics = AnalyticsService.shared
    
    init() {
        analytics.track("onboarding_shown")
    }
    
    func connectStrava() async throws {
        analytics.track("connect_clicked", properties: ["provider": "strava"])
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await StravaService.shared.authenticate()
            analytics.track("oauth_success", properties: ["provider": "strava"])
            step = .permissions
        } catch {
            analytics.track("oauth_fail", properties: ["provider": "strava", "error": error.localizedDescription])
            errorMessage = "Failed to connect to Strava. Please try again."
            throw error
        }
    }
    
    func connectHealth() async throws {
        analytics.track("connect_clicked", properties: ["provider": "health"])
        isLoading = true
        defer { isLoading = false }
        
        let healthStore = HKHealthStore()
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "Health data not available on this device"
            throw OnboardingError.healthNotAvailable
        }
        
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        
        if status == .notDetermined {
            try await healthStore.requestAuthorization(toShare: [], read: [workoutType])
        }
        
        step = .permissions
    }
    
    func importGPX(_ url: URL) async throws {
        analytics.track("connect_clicked", properties: ["provider": "gpx"])
        isLoading = true
        defer { isLoading = false }
        
        do {
            let data = try Data(contentsOf: url)
            let coordinates = GPXParser.parseCoordinates(from: data)
            
            guard !coordinates.isEmpty else {
                throw OnboardingError.gpxParseError
            }
            
            let ride = Ride(
                id: UUID(),
                title: "Imported GPX",
                distanceKm: calculateDistance(coordinates: coordinates),
                elevationGainM: 500, // Estimate
                duration: 3600, // Estimate 1 hour
                coordinates: coordinates,
                date: Date()
            )
            
            rides = [ride]
            step = .permissions
        } catch {
            errorMessage = "Failed to import GPX file. Please check the file format."
            throw error
        }
    }
    
    func loadDemo() {
        analytics.track("connect_clicked", properties: ["provider": "demo"])
        rides = DemoRides.default
        step = .permissions
    }
    
    func importRecent() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Try Strava first if connected
        if StravaService.shared.isAuthenticated {
            rides = try await StravaService.shared.fetchRecentRides(limit: 10)
        }
        // Then try HealthKit
        else if await checkHealthKitPermission() {
            rides = try await HealthKitService.shared.fetchCyclingWorkouts(limit: 10)
        }
        
        if rides.isEmpty {
            loadDemo()
        }
        
        analytics.track("rides_imported", properties: ["count": rides.count])
    }
    
    func buildPoster() async throws {
        guard let bestRide = bestRide() else {
            throw OnboardingError.noRides
        }
        
        let startTime = Date()
        
        // Create GPXRoute from Ride coordinates
        let route = GPXRoute(
            points: bestRide.coordinates.map { coord in
                GPXRoute.Point(lat: coord.latitude, lon: coord.longitude, ele: nil, t: nil)
            },
            distanceMeters: bestRide.distanceKm * 1000,
            duration: bestRide.duration
        )
        
        let design = PosterDesign.default()
        let posterSize = CGSize(width: 600, height: 800)
        
        // Render poster using existing service
        if let _ = await PosterRenderService.shared.renderPoster(
            design: design,
            route: route,
            size: posterSize
        ) {
            // Create Poster model
            poster = Poster(
                id: bestRide.id,
                title: bestRide.title,
                createdAt: Date(),
                thumbnailPath: "onboarding_poster_thumb.jpg",
                filePath: "onboarding_poster.jpg",
                coordinateData: bestRide.coordinates.compactMap { SerializableCoordinate(coordinate: $0) }.data
            )
        }
        
        let renderTime = Date().timeIntervalSince(startTime) * 1000
        
        analytics.track("poster_generated", properties: [
            "ride_id": bestRide.id.uuidString,
            "ms_render": Int(renderTime)
        ])
    }
    
    func savePoster() {
        guard let poster = poster else { return }
        
        // Save to Photos
        PosterExportService.shared.saveToPhotos(poster)
        analytics.track("poster_saved", properties: ["destination": "photos"])
    }
    
    func sharePoster() -> UIImage? {
        guard let poster = poster else { return nil }
        
        // For onboarding, we'll return a placeholder image
        // In the full implementation, this would load the saved poster image
        let placeholderImage = createPlaceholderPosterImage()
        
        analytics.track("poster_saved", properties: ["destination": "share"])
        return placeholderImage
    }
    
    private func createPlaceholderPosterImage() -> UIImage? {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Fill with dark background
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add simple text
            let text = "Your Poster"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasOnboarded")
        analytics.track("onboarding_completed")
        step = .done
    }
    
    // MARK: - Private Methods
    
    private func bestRide() -> Ride? {
        rides.max { lhs, rhs in
            let lhsScore = lhs.distanceKm * 0.6 + lhs.elevationGainM * 0.4
            let rhsScore = rhs.distanceKm * 0.6 + rhs.elevationGainM * 0.4
            return lhsScore < rhsScore
        }
    }
    
    private func checkHealthKitPermission() async -> Bool {
        let healthStore = HKHealthStore()
        let workoutType = HKObjectType.workoutType()
        return healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized
    }
    
    private func calculateDistance(coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0 }
        
        var totalDistance: CLLocationDistance = 0
        for i in 1..<coordinates.count {
            let location1 = CLLocation(latitude: coordinates[i-1].latitude, longitude: coordinates[i-1].longitude)
            let location2 = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            totalDistance += location2.distance(from: location1)
        }
        
        return totalDistance / 1000.0 // Convert to kilometers
    }
}

enum OnboardingError: LocalizedError {
    case healthNotAvailable
    case noRides
    case gpxParseError
    
    var errorDescription: String? {
        switch self {
        case .healthNotAvailable:
            return "Health data is not available on this device"
        case .noRides:
            return "No rides found to create a poster"
        case .gpxParseError:
            return "Could not parse the GPX file"
        }
    }
}

// MARK: - Demo Data
struct DemoRides {
    static let `default`: [Ride] = [
        Ride(
            id: UUID(),
            title: "Golden Gate Loop",
            distanceKm: 45.2,
            elevationGainM: 890,
            duration: 3600 * 2.5, // 2.5 hours
            coordinates: createSampleCoordinates(center: (37.8199, -122.4783), count: 50),
            date: Date().addingTimeInterval(-86400 * 3)
        ),
        Ride(
            id: UUID(),
            title: "Mountain Challenge",
            distanceKm: 72.1,
            elevationGainM: 1540,
            duration: 3600 * 4.2, // 4.2 hours
            coordinates: createSampleCoordinates(center: (40.7589, -111.8883), count: 80),
            date: Date().addingTimeInterval(-86400 * 7)
        )
    ]
    
    private static func createSampleCoordinates(center: (lat: Double, lon: Double), count: Int) -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        for i in 0..<count {
            let progress = Double(i) / Double(count)
            let lat = center.lat + sin(progress * .pi * 2) * 0.01 + progress * 0.02
            let lon = center.lon + cos(progress * .pi * 2) * 0.01 + progress * 0.03
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
}

// MARK: - Supporting Models
struct Ride {
    let id: UUID
    let title: String
    let distanceKm: Double
    let elevationGainM: Double
    let duration: TimeInterval
    let coordinates: [CLLocationCoordinate2D]
    let date: Date
}