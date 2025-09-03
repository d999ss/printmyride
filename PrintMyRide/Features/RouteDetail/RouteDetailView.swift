import SwiftUI
import CoreLocation

/// Native route detail view that handles poster rendering lazily
struct RouteDetailView: View {
    let poster: Poster
    @State private var posterImage: UIImage?
    @State private var isGeneratingPoster = false
    @State private var exportMessage: String?
    @State private var showPaywall = false
    @State private var showPosterFocus = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionGate = SubscriptionGate()
    
    private var coords: [CLLocationCoordinate2D] {
        let result = poster.coordinates ?? DemoCoordsLoader.coords(forTitle: poster.title)
        print("[RouteDetailView] Loaded \(result.count) coordinates for poster '\(poster.title)'")
        return result
    }
    
    private var routeStats: (distance: Double, elevation: Double, duration: TimeInterval?) {
        guard !coords.isEmpty else { return (0, 0, nil) }
        
        let distance = RouteStatsCalculator.distance(coords: coords)
        let elevation = RouteStatsCalculator.elevationGain(coords: coords)
        let duration = RouteStatsCalculator.estimatedDuration(coords: coords)
        
        return (distance, elevation, duration)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Poster Preview Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Poster Preview")
                            .font(.headline)
                        Spacer()
                        
                        if isGeneratingPoster {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    // Poster Image or Generate Button
                    Group {
                        if let posterImage = posterImage {
                            Image(uiImage: posterImage)
                                .resizable()
                                .scaledToFit()
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 2)
                                .onTapGesture {
                                    showPosterFocus = true
                                }
                        } else {
                            Button {
                                if subscriptionGate.isSubscribed {
                                    Task { await generatePoster() }
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Image(systemName: "photo.artframe")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.secondary)
                                        
                                        if !subscriptionGate.isSubscribed {
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.yellow)
                                                .offset(x: 20, y: -20)
                                        }
                                    }
                                    
                                    Text("Generate Poster")
                                        .font(.headline)
                                    
                                    Text(subscriptionGate.isSubscribed ? 
                                         "Create a beautiful poster of your ride" :
                                         "Upgrade to Pro to create stunning posters")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color(.systemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Export Message
                    if let exportMessage = exportMessage {
                        Text(exportMessage)
                            .font(.caption)
                            .foregroundStyle(exportMessage.hasPrefix("✅") ? .green : .red)
                    }
                }
                .glass()
                
                // Route Stats Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Route Statistics")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            value: String(format: "%.1f", routeStats.distance),
                            unit: "miles",
                            icon: "map"
                        )
                        
                        StatCard(
                            value: String(format: "%.0f", routeStats.elevation),
                            unit: "ft elev",
                            icon: "arrow.up.forward"
                        )
                        
                        if let duration = routeStats.duration {
                            let hours = Int(duration) / 3600
                            let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
                            let timeString = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
                            
                            StatCard(
                                value: timeString,
                                unit: "time",
                                icon: "clock"
                            )
                        }
                    }
                }
                .glass()
                
                // Actions Section (Only visible when poster exists)
                if posterImage != nil {
                    VStack(spacing: 12) {
                        Button {
                            sharePoster()
                        } label: {
                            Label("Share Poster", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            if subscriptionGate.isSubscribed {
                                exportPoster()
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            HStack {
                                Label("Export High-Res", systemImage: "square.and.arrow.down")
                                if !subscriptionGate.isSubscribed {
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .glass()
                }
            }
            .padding()
        }
        .navigationTitle(poster.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCachedPoster()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallCardView()
                .environmentObject(subscriptionGate)
        }
        .fullScreenCover(isPresented: $showPosterFocus) {
            if let posterImage = posterImage {
                PosterFocusView(image: posterImage)
            }
        }
    }
    
    @MainActor
    private func generatePoster() async {
        guard !coords.isEmpty, !isGeneratingPoster else { return }
        
        isGeneratingPoster = true
        defer { isGeneratingPoster = false }
        
        // Create input for new poster renderer
        let input = RidePosterInput(
            coordinates: coords,
            distanceMeters: routeStats.distance * 1609.34, // miles to meters
            movingSeconds: Int(routeStats.duration ?? 3600), // fallback 1 hour
            elevationGainMeters: routeStats.elevation * 0.3048, // feet to meters
            centroid: CLLocationCoordinate2D(
                latitude: coords.map(\.latitude).reduce(0, +) / Double(coords.count),
                longitude: coords.map(\.longitude).reduce(0, +) / Double(coords.count)
            ),
            date: Date(), // TODO: get actual ride date from poster
            title: poster.title,
            units: .imperial, // TODO: get from user settings
            theme: .terracotta
        )
        
        do {
            let renderer = PosterRenderer()
            let pngData = try renderer.render(input, kind: .png(scale: 2.0))
            posterImage = UIImage(data: pngData)
            
            if posterImage != nil {
                await savePosterToCache()
                exportMessage = "✅ Poster generated successfully"
            } else {
                exportMessage = "❌ Failed to generate poster"
            }
        } catch {
            exportMessage = "❌ Failed to generate poster: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func loadCachedPoster() async {
        // Check if we have a cached poster
        let filename = poster.snapshotFilename
        if let cached = PosterSnapshotStore.loadSnapshot(named: filename) {
            posterImage = cached
        }
    }
    
    private func savePosterToCache() async {
        guard let image = posterImage else { return }
        
        // Save to poster snapshot store
        PosterSnapshotStore.shared.saveSnapshot(image, for: poster)
        
        // Also save to documents directory for export
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let posterURL = documentsPath.appendingPathComponent(poster.filePath)
        
        if let imageData = image.pngData() {
            try? imageData.write(to: posterURL)
        }
    }
    
    private func sharePoster() {
        guard let image = posterImage else { return }
        
        // Create rich sharing content for iMessage
        let posterTitle = poster.title.isEmpty ? "My Ride" : poster.title
        let routeStats = formatRouteStats()
        let routeURL = createShareableRouteURL()
        
        // Use enhanced sharing with rich link preview
        ShareSheet.presentRichShare(
            title: posterTitle,
            subtitle: routeStats,
            image: image,
            url: routeURL
        )
    }
    
    private func formatRouteStats() -> String {
        let distance = String(format: "%.1f", routeStats.distance)
        let time = routeStats.duration.map { formatDuration($0) } ?? "Unknown"
        let elevation = String(format: "%.0f", routeStats.elevation)
        
        return "\(distance) mi • \(time) • \(elevation) ft elevation"
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func createShareableRouteURL() -> URL {
        // Create a custom URL scheme for the app that can be opened from iMessage
        let baseURL = "printmyride://route"
        
        // Encode basic route info
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "title", value: poster.title),
            URLQueryItem(name: "distance", value: String(routeStats.distance)),
            URLQueryItem(name: "duration", value: String(routeStats.duration ?? 0)),
            URLQueryItem(name: "elevation", value: String(routeStats.elevation))
        ]
        
        return components.url ?? URL(string: baseURL)!
    }
    
    private func exportPoster() {
        guard posterImage != nil else { return }
        
        // Generate high-resolution version for export
        Task {
            let highResImage = SimpleArtisticPoster.render(
                title: poster.title,
                coordinates: coords,
                size: CGSize(width: 2400, height: 3600) // 300 DPI at 8x12 inches
            )
            
            await MainActor.run {
                if let highRes = highResImage {
                    let activityVC = UIActivityViewController(activityItems: [highRes], applicationActivities: nil)
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityVC, animated: true)
                    }
                    exportMessage = "✅ High-resolution poster exported"
                } else {
                    exportMessage = "❌ Failed to export high-res poster"
                }
            }
        }
    }
}

// MARK: - Stat Card Component
private struct StatCard: View {
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.quaternarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Poster Focus View
struct PosterFocusView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Header with close button
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .padding()
                }
                
                Spacer()
                
                // Zoomable poster image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            // Pinch to zoom
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastMagnification
                                    scale *= delta
                                    scale = max(1.0, min(scale, 4.0)) // Limit zoom range
                                    lastMagnification = value
                                }
                                .onEnded { _ in
                                    lastMagnification = 1.0
                                    if scale < 1.2 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                            offset = .zero
                                        }
                                    }
                                },
                            
                            // Drag to pan
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = value.translation
                                    }
                                }
                                .onEnded { _ in
                                    if scale <= 1.0 {
                                        withAnimation(.spring()) {
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                    )
                
                Spacer()
                
                // Tap hint
                Text("Pinch to zoom • Tap Done to close")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom)
            }
        }
        .onTapGesture(count: 2) {
            // Double tap to reset zoom
            withAnimation(.spring()) {
                scale = 1.0
                offset = .zero
            }
        }
        .statusBarHidden()
    }
}