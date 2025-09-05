import SwiftUI
import CoreLocation

/// Native ride detail view that handles poster rendering lazily
struct RideDetailView: View {
    let poster: Poster
    @State private var posterImage: UIImage?
    @State private var isGeneratingPoster = false
    @State private var exportMessage: String?
    @State private var showPaywall = false
    @State private var showPosterFocus = false
    @State private var isFavorite = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionGate = SubscriptionGate()
    
    private var coords: [CLLocationCoordinate2D] {
        let result = poster.coordinates ?? DemoCoordsLoader.coords(forTitle: poster.title)
        print("[RideDetailView] Loaded \(result.count) coordinates for poster '\(poster.title)'")
        return result
    }
    
    private var rideStats: (distance: Double, elevation: Double, duration: TimeInterval?) {
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
                                print("🔥 BUTTON TAPPED - isSubscribed: \(subscriptionGate.isSubscribed)")
                                exportMessage = "🔄 Button tapped, starting..."
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
                            value: String(format: "%.1f", rideStats.distance),
                            unit: "miles",
                            icon: "map"
                        )
                        
                        StatCard(
                            value: String(format: "%.0f", rideStats.elevation),
                            unit: "ft elev",
                            icon: "arrow.up.forward"
                        )
                        
                        if let duration = rideStats.duration {
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
                
                // Purchase Options Section (only show if poster exists)
                if posterImage != nil {
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            Text("Order Your Poster")
                                .font(.title2.weight(.semibold))
                            
                            Text("Get your route printed on premium paper and shipped directly to you")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 12) {
                            NavigationLink("Order Physical Poster") {
                                MockCheckoutView(poster: poster)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(Color(UIColor.systemBrown))
                            .frame(height: 50)
                            
                            Button("Share Poster") {
                                sharePoster()
                            }
                            .buttonStyle(.bordered)
                            .frame(height: 44)
                        }
                    }
                    .glass()
                }
                
                // Primary CTA Section
                VStack(spacing: 12) {
                    // Primary CTA: Send to Studio
                    Button {
                        sendToStudio()
                    } label: {
                        Label("Send to Studio", systemImage: "map")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .background(LiquidGlassCapsule())
                    .liquidGlassCapsule()
                }
                .glass()
                
                // Secondary Actions Section
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Share GPX
                        Button {
                            shareGPX()
                        } label: {
                            Label("Share GPX", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.bordered)
                        
                        // Favorite
                        Button {
                            toggleFavorite()
                        } label: {
                            Label(isFavorite ? "Remove Favorite" : "Add Favorite", 
                                  systemImage: isFavorite ? "heart.fill" : "heart")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.bordered)
                        .tint(isFavorite ? .pink : .primary)
                    }
                    
                    // Delete
                    Button {
                        deleteRide()
                    } label: {
                        Label("Delete Ride", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .glass()
            }
            .padding()
        }
        .navigationTitle("Ride")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar) // Hide bottom navigation for focused experience
        .task {
            await loadCachedPoster()
            loadFavoriteStatus()
        }
        .onAppear {
            // Hide tab bar for focused checkout experience
            NotificationCenter.default.post(name: .pmrHideTabBar, object: nil)
        }
        .onDisappear {
            // Show tab bar when leaving this view
            NotificationCenter.default.post(name: .pmrShowTabBar, object: nil)
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
        print("[RideDetailView] Generate poster called - coords count: \(coords.count)")
        guard !coords.isEmpty, !isGeneratingPoster else { 
            print("[RideDetailView] Generate poster guard failed - coords empty: \(coords.isEmpty), isGenerating: \(isGeneratingPoster)")
            return 
        }
        
        isGeneratingPoster = true
        defer { isGeneratingPoster = false }
        
        // Create input for new poster renderer
        let _ = RidePosterInput(
            coordinates: coords,
            distanceMeters: rideStats.distance * 1609.34, // miles to meters
            movingSeconds: Int(rideStats.duration ?? 3600), // fallback 1 hour
            elevationGainMeters: rideStats.elevation * 0.3048, // feet to meters
            centroid: CLLocationCoordinate2D(
                latitude: coords.map(\.latitude).reduce(0, +) / Double(coords.count),
                longitude: coords.map(\.longitude).reduce(0, +) / Double(coords.count)
            ),
            date: Date(), // Uses current date as fallback
            title: poster.title,
            units: .imperial, // Default to imperial units
            theme: .terracotta
        )
        
        exportMessage = "🔄 Creating simple test poster..."
        // Create a simple test poster for now to bypass map rendering issues
        posterImage = createSimpleTestPoster()
        
        if posterImage != nil {
            exportMessage = "🔄 Saving to cache..."
            await savePosterToCache()
            exportMessage = "✅ Test poster generated successfully"
        } else {
            exportMessage = "❌ Failed to create test poster"
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
        let distance = String(format: "%.1f", rideStats.distance)
        let time = rideStats.duration.map { formatDuration($0) } ?? "Unknown"
        let elevation = String(format: "%.0f", rideStats.elevation)
        
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
            URLQueryItem(name: "distance", value: String(rideStats.distance)),
            URLQueryItem(name: "duration", value: String(rideStats.duration ?? 0)),
            URLQueryItem(name: "elevation", value: String(rideStats.elevation))
        ]
        
        return components.url ?? URL(string: baseURL)!
    }
    
    private func sendToStudio() {
        // Navigate to Studio tab with this ride selected
        // This will be handled by the router/navigation system
        NotificationCenter.default.post(
            name: .pmrStudioRideSelected,
            object: poster
        )
        dismiss()
    }
    
    private func shareGPX() {
        guard !coords.isEmpty else { return }
        
        // Create GPX content
        let gpxContent = GPXGenerator.generate(
            coordinates: coords,
            title: poster.title,
            description: formatRouteStats()
        )
        
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(poster.title.isEmpty ? "ride" : poster.title).gpx")
        
        do {
            try gpxContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Present share sheet
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        } catch {
            print("Failed to create GPX file: \(error)")
        }
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        
        // Update favorite status in poster store
        FavoritesStore.shared.toggle(poster.id)
    }
    
    private func deleteRide() {
        // Show confirmation alert first
        let alert = UIAlertController(
            title: "Delete Ride",
            message: "This will permanently delete this ride and cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            // Remove from poster store
            // Note: PosterStore doesn't have removePoster method yet
            // TODO: Implement poster removal
            
            // Remove cached images
            // TODO: Implement removeSnapshot method in PosterSnapshotStore
            // PosterSnapshotStore.shared.removeSnapshot(for: poster)
            
            // Remove from favorites if needed
            if FavoritesStore.shared.contains(poster.id) {
                FavoritesStore.shared.toggle(poster.id)
            }
            
            // Dismiss the view
            dismiss()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func loadFavoriteStatus() {
        isFavorite = FavoritesStore.shared.contains(poster.id)
    }
    
    private func createSimpleTestPoster() -> UIImage? {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            cgContext.setFillColor(UIColor.systemBackground.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Title
            let title = poster.title.isEmpty ? "Test Ride" : poster.title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: 50,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Stats
            let stats = "\(String(format: "%.1f", rideStats.distance)) mi • \(String(format: "%.0f", rideStats.elevation)) ft"
            let statsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let statsSize = stats.size(withAttributes: statsAttributes)
            let statsRect = CGRect(
                x: (size.width - statsSize.width) / 2,
                y: 100,
                width: statsSize.width,
                height: statsSize.height
            )
            stats.draw(in: statsRect, withAttributes: statsAttributes)
            
            // Simple route visualization
            if !coords.isEmpty {
                cgContext.setStrokeColor(UIColor.systemBrown.cgColor)
                cgContext.setLineWidth(3)
                
                let padding: CGFloat = 50
                let plotArea = CGRect(
                    x: padding,
                    y: 200,
                    width: size.width - 2 * padding,
                    height: 200
                )
                
                // Simple line connecting first and last coordinate
                cgContext.beginPath()
                cgContext.move(to: CGPoint(x: plotArea.minX, y: plotArea.midY))
                cgContext.addLine(to: CGPoint(x: plotArea.maxX, y: plotArea.midY))
                cgContext.strokePath()
            }
        }
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