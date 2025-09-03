import SwiftUI
import MapKit

struct RecordingView: View {
    @StateObject private var locationService = LocationRecordingService.shared
    @StateObject private var subscriptionGate = SubscriptionGate()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPermissionAlert = false
    @State private var showingSaveDialog = false
    @State private var routeTitle = ""
    @State private var completedRoute: GPXRoute?
    @State private var showPaywall = false
    
    // Map view properties
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()
                
                // Recording Controls Overlay
                VStack {
                    Spacer()
                    
                    // Stats Display
                    if locationService.isRecording {
                        StatsPanel()
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                    
                    // Control Panel
                    ControlPanel { route in
                        completedRoute = route
                        showingSaveDialog = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 50) // Account for tab bar
                }
            }
            .navigationTitle("Record Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if locationService.isRecording {
                            _ = locationService.stopRecording()
                        }
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkLocationPermission()
        }
        .alert("Location Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("PrintMyRide needs location access to record your routes. Please enable location permissions in Settings.")
        }
        .alert("Save Route", isPresented: $showingSaveDialog) {
            TextField("Route name", text: $routeTitle)
            Button("Save") {
                saveRoute()
            }
            Button("Cancel", role: .cancel) {
                completedRoute = nil
                routeTitle = ""
            }
        } message: {
            if let route = completedRoute {
                Text("Great ride! You recorded \(String(format: "%.1f", route.distanceInMiles)) miles in \(route.durationInMinutes?.formatted() ?? "0") minutes.")
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallCardView()
                .environmentObject(subscriptionGate)
        }
    }
    
    private func checkLocationPermission() {
        switch locationService.authorizationStatus {
        case .denied, .restricted:
            showingPermissionAlert = true
        case .notDetermined:
            locationService.requestPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
    
    private func saveRoute() {
        guard let route = completedRoute else { return }
        
        if !subscriptionGate.isSubscribed {
            showPaywall = true
            return
        }
        
        let title = routeTitle.isEmpty ? "Route \(Date().formatted(date: .abbreviated, time: .omitted))" : routeTitle
        
        Task {
            // Convert GPXRoute to Poster and save
            let coordinates = route.points.map { $0.coordinate }
            
            let poster = Poster(
                id: UUID(),
                title: title,
                createdAt: Date(),
                thumbnailPath: "",
                filePath: ""
            )
            var posterWithCoords = poster
            posterWithCoords.coordinates = coordinates
            
            await MainActor.run {
                PosterStore.shared.add(posterWithCoords)
                
                // Clear state and dismiss
                completedRoute = nil
                routeTitle = ""
                dismiss()
            }
        }
    }
}

// MARK: - Stats Panel
private struct StatsPanel: View {
    @ObservedObject private var locationService = LocationRecordingService.shared
    
    var body: some View {
        HStack(spacing: 16) {
            StatItem(
                title: "Distance",
                value: String(format: "%.2f mi", locationService.distanceInMiles),
                icon: "figure.walk"
            )
            
            StatItem(
                title: "Duration",
                value: locationService.formattedDuration,
                icon: "stopwatch"
            )
            
            StatItem(
                title: "Speed",
                value: String(format: "%.1f mph", locationService.currentSpeedMPH),
                icon: "speedometer"
            )
            
            if locationService.elevationGain > 0 {
                StatItem(
                    title: "Elevation",
                    value: String(format: "%.0f ft", locationService.elevationGainFeet),
                    icon: "mountain.2"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

private struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Control Panel
private struct ControlPanel: View {
    @ObservedObject private var locationService = LocationRecordingService.shared
    let onRouteCompleted: (GPXRoute) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if locationService.isRecording {
                // Pause/Resume button
                Button {
                    if locationService.isPaused {
                        locationService.resumeRecording()
                    } else {
                        locationService.pauseRecording()
                    }
                } label: {
                    Image(systemName: locationService.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.orange, in: Circle())
                }
                .buttonStyle(.plain)
                
                // Stop button
                Button {
                    stopRecording()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.red, in: Circle())
                }
                .buttonStyle(.plain)
            } else {
                // Start button
                Button {
                    locationService.startRecording()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "location")
                            .font(.title3)
                        Text("Start Recording")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(.green, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, locationService.isRecording ? 40 : 0)
    }
    
    private func stopRecording() {
        if let route = locationService.stopRecording() {
            onRouteCompleted(route)
        }
    }
}