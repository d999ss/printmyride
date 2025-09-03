import Foundation
import CoreLocation
import Combine
import UIKit

@MainActor
final class LocationRecordingService: NSObject, ObservableObject {
    static let shared = LocationRecordingService()
    
    // MARK: - Published State
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var recordingError: String?
    
    // Current session data
    @Published var currentRoute: [CLLocation] = []
    @Published var distance: Double = 0 // meters
    @Published var duration: TimeInterval = 0
    @Published var averageSpeed: Double = 0 // m/s
    @Published var currentSpeed: Double = 0 // m/s
    @Published var elevationGain: Double = 0 // meters
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var recordingStartTime: Date?
    private var lastElevation: Double?
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupLocationManager()
        startLocationStatusMonitoring()
    }
    
    // MARK: - Location Manager Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters
        locationManager.allowsBackgroundLocationUpdates = false // For now, keep in foreground
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    private func startLocationStatusMonitoring() {
        // Monitor app state changes
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppForeground()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            recordingError = "Location access denied. Enable in Settings to record routes."
        case .authorizedWhenInUse:
            // Try to upgrade to always authorization for better recording
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            recordingError = "Location permission required to record routes"
            requestPermission()
            return
        }
        
        // Reset state
        currentRoute.removeAll()
        distance = 0
        duration = 0
        averageSpeed = 0
        currentSpeed = 0
        elevationGain = 0
        lastElevation = nil
        recordingError = nil
        
        // Start recording
        recordingStartTime = Date()
        isRecording = true
        isPaused = false
        
        locationManager.startUpdatingLocation()
        startDurationTimer()
        
        print("[GPS] Started recording route")
    }
    
    func pauseRecording() {
        guard isRecording && !isPaused else { return }
        
        isPaused = true
        locationManager.stopUpdatingLocation()
        
        print("[GPS] Paused recording")
    }
    
    func resumeRecording() {
        guard isRecording && isPaused else { return }
        
        isPaused = false
        locationManager.startUpdatingLocation()
        
        print("[GPS] Resumed recording")
    }
    
    func stopRecording() -> GPXRoute? {
        guard isRecording else { return nil }
        
        locationManager.stopUpdatingLocation()
        isRecording = false
        isPaused = false
        
        let route = generateGPXRoute()
        
        // Reset state
        currentRoute.removeAll()
        distance = 0
        duration = 0
        averageSpeed = 0
        currentSpeed = 0
        elevationGain = 0
        recordingStartTime = nil
        lastElevation = nil
        
        print("[GPS] Stopped recording. Generated route with \(route?.points.count ?? 0) points")
        
        return route
    }
    
    // MARK: - Private Helpers
    private func startDurationTimer() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isRecording, !self.isPaused else { return }
                self.updateDuration()
            }
            .store(in: &cancellables)
    }
    
    private func updateDuration() {
        guard let startTime = recordingStartTime else { return }
        duration = Date().timeIntervalSince(startTime)
    }
    
    private func processNewLocation(_ location: CLLocation) {
        guard isRecording && !isPaused else { return }
        
        // Filter out poor accuracy readings
        guard location.horizontalAccuracy <= 50 else { return }
        
        currentRoute.append(location)
        currentSpeed = max(0, location.speed) // location.speed can be negative
        
        // Calculate distance
        if currentRoute.count > 1 {
            let previous = currentRoute[currentRoute.count - 2]
            let segment = location.distance(from: previous)
            distance += segment
        }
        
        // Calculate average speed
        if duration > 0 {
            averageSpeed = distance / duration
        }
        
        // Calculate elevation gain
        if let altitude = location.altitude as Double? {
            if let lastElevation = lastElevation {
                let gain = altitude - lastElevation
                if gain > 0 {
                    elevationGain += gain
                }
            }
            lastElevation = altitude
        }
    }
    
    private func generateGPXRoute() -> GPXRoute? {
        guard !currentRoute.isEmpty else { return nil }
        
        let points = currentRoute.map { location in
            GPXRoute.Point(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude,
                ele: location.altitude,
                t: location.timestamp
            )
        }
        
        return GPXRoute(
            points: points,
            distanceMeters: distance,
            duration: duration
        )
    }
    
    private func handleAppBackground() {
        // For now, pause recording when app goes to background
        // In a full implementation, you'd request background location permission
        if isRecording && !isPaused {
            pauseRecording()
        }
    }
    
    private func handleAppForeground() {
        // Resume if we were recording before
        if isRecording && isPaused {
            resumeRecording()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationRecordingService: @preconcurrency CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            processNewLocation(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            recordingError = "Location error: \(error.localizedDescription)"
            print("[GPS] Location error: \(error)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            authorizationStatus = status
            
            switch status {
            case .denied, .restricted:
                recordingError = "Location access denied. Enable in Settings to record routes."
                if isRecording {
                    _ = stopRecording()
                }
            case .authorizedWhenInUse, .authorizedAlways:
                recordingError = nil
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Helper Extensions
extension LocationRecordingService {
    var distanceInMiles: Double {
        distance * 0.000621371
    }
    
    var distanceInKilometers: Double {
        distance / 1000
    }
    
    var currentSpeedMPH: Double {
        currentSpeed * 2.23694
    }
    
    var currentSpeedKPH: Double {
        currentSpeed * 3.6
    }
    
    var averageSpeedMPH: Double {
        averageSpeed * 2.23694
    }
    
    var averageSpeedKPH: Double {
        averageSpeed * 3.6
    }
    
    var elevationGainFeet: Double {
        elevationGain * 3.28084
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}