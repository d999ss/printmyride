import SwiftUI
import UniformTypeIdentifiers
import CoreLocation

struct StudioHubView: View {
    @State private var selectedRide: Poster?
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var library: LibraryStore
    @State private var showingGPXPicker = false
    @State private var isImportingGPX = false
    @State private var importError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Studio welcome header
                VStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("Poster Studio")
                    .font(.largeTitle.bold())
                
                Text("Transform your rides into art")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 120)
            
            // Main CTAs
            VStack(spacing: 16) {
                if authService.isStravaConnected {
                    Button {
                        // Navigate to rides to select one
                        router.selectedTab = 1
                    } label: {
                        Label("Select a Ride", systemImage: "bicycle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    NavigationLink(destination: StravaActivitiesView()) {
                        Label("View All Activities", systemImage: "list.bullet")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.bordered)
                } else {
                    NavigationLink(destination: StravaConnectionView()) {
                        Label("Connect to Strava", systemImage: "link")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button {
                    showingGPXPicker = true
                } label: {
                    Label("Import GPX File", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.bordered)
                
                NavigationLink(destination: PosterPreviewView(poster: StorePoster.sample)) {
                    Label("Preview Store Poster", systemImage: "photo")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            }
        }
        .navigationTitle("Studio")
        .navigationBarTitleDisplayMode(.large)
.onReceive(NotificationCenter.default.publisher(for: .pmrStudioRideSelected)) { notification in
            if let poster = notification.object as? Poster {
                selectedRide = poster
                // Switch to Studio tab
                router.selectedTab = 0
            }
        }
        .fileImporter(
            isPresented: $showingGPXPicker,
            allowedContentTypes: [.gpx],
            allowsMultipleSelection: false
        ) { result in
            Task { await handleGPXImport(result) }
        }
        .overlay {
            if isImportingGPX {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Importing GPX file...")
                                .font(.headline)
                        }
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
            }
        }
        .alert("Import Error", isPresented: .constant(importError != nil)) {
            Button("OK") { importError = nil }
        } message: {
            if let error = importError {
                Text(error)
            }
        }
    }
    
    private func handleGPXImport(_ result: Result<[URL], Error>) async {
        isImportingGPX = true
        defer { isImportingGPX = false }
        
        do {
            guard let fileURL = try result.get().first else {
                importError = "No file selected"
                return
            }
            
            // Load GPX file
            guard let gpxRoute = GPXImporter.load(url: fileURL) else {
                importError = "Invalid GPX file format"
                return
            }
            
            // Extract filename as title
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            let title = fileName.isEmpty ? "Imported Route" : fileName
            
            // Format route data
            let distanceMiles = gpxRoute.distanceMeters * 0.000621371
            let distance = String(format: "%.1f mi", distanceMiles)
            let date = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
            
            // Convert GPX points to CLLocationCoordinate2D
            let coordinates = gpxRoute.points.map { point in
                CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon)
            }
            
            // Save GPX data to a temporary file
            let tempGPXURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("imported_\(UUID().uuidString).gpx")
            do {
                let gpxData = try Data(contentsOf: fileURL)
                try gpxData.write(to: tempGPXURL)
            } catch {
                importError = "Failed to save GPX data: \(error.localizedDescription)"
                return
            }
            
            // Generate thumbnail
            guard let thumbnailImage = await AsyncRouteThumbnailProvider.shared.thumbnail(
                for: coordinates, 
                size: CGSize(width: 300, height: 200)
            ) else {
                importError = "Failed to generate thumbnail"
                return
            }
            
            guard let thumbnailPNG = thumbnailImage.pngData() else {
                importError = "Failed to convert thumbnail to PNG"
                return
            }
            
            // Create poster design and text
            let design = PosterDesign.default()
            var posterText = PosterText()
            posterText.title = title
            posterText.subtitle = "\(distance) • \(date)"
            
            // Add to library using LibraryStore
            await MainActor.run {
                library.add(
                    design: design,
                    routeURL: tempGPXURL,
                    thumbnailPNG: thumbnailPNG,
                    title: title,
                    text: posterText
                )
                
                // Navigate to first tab (where projects are displayed)
                router.selectedTab = 1
            }
            
        } catch {
            importError = "Failed to import GPX file: \(error.localizedDescription)"
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}