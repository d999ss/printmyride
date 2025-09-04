import SwiftUI
import CoreLocation

// MARK: - RidesListView (Native iOS List)
struct RidesListView: View {
    @ObservedObject private var posterStore = PosterStore.shared
    @State private var selectedFilter: RideFilter = .all
    @StateObject private var subscriptionGate = SubscriptionGate()
    @State private var showingRecordingView = false
    
    private enum RideFilter: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
    }
    
    private var filteredRides: [Poster] {
        let rides = posterStore.posters
        switch selectedFilter {
        case .all:
            return rides
        case .favorites:
            return rides.filter { FavoritesStore.shared.contains($0.id) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Demo data loader - temporary for testing
                if posterStore.posters.isEmpty {
                    Button("Load Demo Routes") {
                        loadDemoRoutesSync()
                    }
                    .padding()
                }
// Custom segmented control for perfect TapDoctor compliance
                HStack(spacing: 0) {
                    ForEach(RideFilter.allCases, id: \.self) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 15, weight: selectedFilter == filter ? .semibold : .regular))
                                .foregroundColor(selectedFilter == filter ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)  // Guaranteed 50pt height
                                .contentShape(Rectangle())  // Entire area tappable
                                .background(
                                    selectedFilter == filter ?
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(UIColor.systemGray5))
                                        .padding(2) : nil
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(UIColor.separator), lineWidth: 0.5)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // Clean list
                List(filteredRides) { ride in
                    NavigationLink(destination: RideDetailView(poster: ride)) {
                        RideRowView(ride: ride, subscriptionGate: subscriptionGate)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.visible)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            FavoritesStore.shared.toggle(ride.id)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            let isFavorite = FavoritesStore.shared.contains(ride.id)
                            Label(isFavorite ? "Unfavorite" : "Favorite",
                                  systemImage: isFavorite ? "heart.slash" : "heart.fill")
                        }
                        .tint(.pink)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(.clear)
            }
            .navigationTitle("Rides")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingRecordingView = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingRecordingView) {
                RecordingView()
            }
            .onAppear {
                // Auto-load demo routes if empty (for testing)
                if posterStore.posters.isEmpty {
                    loadDemoRoutesSync()
                }
            }
        }
    }
    
    // MARK: - Demo Data Loading
    private func loadDemoRoutesSync() {
        // Generate 6 demo routes with different characteristics
        let demoRoutes = [
            ("Mountain Climb Challenge", createMountainRoute(), Date().addingTimeInterval(-86400 * 5)),
            ("Coastal Ride", createCoastalRoute(), Date().addingTimeInterval(-86400 * 12)),
            ("City Loop", createCityRoute(), Date().addingTimeInterval(-86400 * 3)),
            ("Forest Trail", createForestRoute(), Date().addingTimeInterval(-86400 * 8)),
            ("Desert Exploration", createDesertRoute(), Date().addingTimeInterval(-86400 * 1)),
            ("River Valley Tour", createRiverRoute(), Date().addingTimeInterval(-86400 * 18))
        ]
        
        for (title, coords, date) in demoRoutes {
            var poster = Poster(
                id: UUID(),
                title: title,
                createdAt: date,
                thumbnailPath: "",
                filePath: "",
                coordinateData: nil
            )
            poster.coordinates = coords  // Use computed property setter
            posterStore.add(poster)
            print("Added route: \(title) with \(coords.count) coordinates")
        }
    }
    
    private func loadDemoRoutes() async {
        // Generate 6 demo routes with different characteristics
        let demoRoutes = [
            ("Mountain Climb Challenge", createMountainRoute(), Date().addingTimeInterval(-86400 * 5)),
            ("Coastal Ride", createCoastalRoute(), Date().addingTimeInterval(-86400 * 12)),
            ("City Loop", createCityRoute(), Date().addingTimeInterval(-86400 * 3)),
            ("Forest Trail", createForestRoute(), Date().addingTimeInterval(-86400 * 8)),
            ("Desert Exploration", createDesertRoute(), Date().addingTimeInterval(-86400 * 1)),
            ("River Valley Tour", createRiverRoute(), Date().addingTimeInterval(-86400 * 18))
        ]
        
        for (title, coords, date) in demoRoutes {
            let poster = Poster(
                id: UUID(),
                title: title,
                createdAt: date,
                thumbnailPath: "",
                filePath: ""
            )
            var posterWithCoords = poster
            posterWithCoords.coordinates = coords
            posterStore.add(posterWithCoords)
        }
    }
    
    // Demo route generators
    private func createMountainRoute() -> [CLLocationCoordinate2D] {
        // Simulate a mountain climbing route - elevation gain pattern
        var coords: [CLLocationCoordinate2D] = []
        let baseLat = 40.7589
        let baseLon = -111.8883 // Park City area
        
        for i in 0...50 {
            let progress = Double(i) / 50.0
            let lat = baseLat + (progress * 0.02) + sin(progress * 3.14159) * 0.005
            let lon = baseLon + (progress * 0.03) + cos(progress * 3.14159) * 0.004
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
    
    private func createCoastalRoute() -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        let baseLat = 37.8199 // San Francisco area
        let baseLon = -122.4783
        
        for i in 0...40 {
            let progress = Double(i) / 40.0
            let lat = baseLat + (progress * 0.015) + sin(progress * 6.28) * 0.003
            let lon = baseLon + (progress * 0.025)
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
    
    private func createCityRoute() -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        let baseLat = 40.7831 // NYC Central Park
        let baseLon = -73.9712
        
        for i in 0...30 {
            let progress = Double(i) / 30.0
            let lat = baseLat + sin(progress * 12.56) * 0.005 // Multiple loops
            let lon = baseLon + cos(progress * 12.56) * 0.008
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
    
    private func createForestRoute() -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        let baseLat = 45.3734 // Portland area
        let baseLon = -121.7057
        
        for i in 0...35 {
            let progress = Double(i) / 35.0
            let lat = baseLat + (progress * 0.018) + sin(progress * 9.42) * 0.004
            let lon = baseLon + (progress * 0.022) + cos(progress * 7.85) * 0.006
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
    
    private func createDesertRoute() -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        let baseLat = 33.7490 // Phoenix area
        let baseLon = -112.0740
        
        for i in 0...25 {
            let progress = Double(i) / 25.0
            let lat = baseLat + (progress * 0.012) + sin(progress * 4.71) * 0.003
            let lon = baseLon + (progress * 0.020)
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
    
    private func createRiverRoute() -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        let baseLat = 39.7392 // Denver area
        let baseLon = -104.9903
        
        for i in 0...45 {
            let progress = Double(i) / 45.0
            let lat = baseLat + (progress * 0.016) + sin(progress * 15.71) * 0.002 // Winding river pattern
            let lon = baseLon + (progress * 0.024) + cos(progress * 15.71) * 0.003
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
}

// MARK: - Native Stat View Component
private struct StatView: View {
    let value: String
    let label: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Native Ride Row
private struct RideRowView: View {
    let ride: Poster
    let subscriptionGate: SubscriptionGate
    @State private var isFavorite: Bool = false
    
    private var rideStats: (distance: Double, elevation: Double, duration: TimeInterval?) {
        guard let coords = ride.coordinates else { 
            return (0, 0, nil)
        }
        
        let distance = RouteStatsCalculator.distance(coords: coords)
        let elevation = RouteStatsCalculator.elevationGain(coords: coords)
        let duration = RouteStatsCalculator.estimatedDuration(coords: coords)
        
        return (distance, elevation, duration)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Ride thumbnail with glass background
            Image(systemName: "map")
                .symbolRenderingMode(.hierarchical)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.quaternarySystemFill))
                }
            
            // Ride info
            VStack(alignment: .leading, spacing: 2) {
                Text(ride.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(String(format: "%.1f mi", rideStats.distance)) • \(String(format: "%.0f ft", rideStats.elevation)) • \(formatDuration(rideStats.duration))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Apple-style favorite button
            FavoriteButton(isFav: $isFavorite) {
                FavoritesStore.shared.toggle(ride.id)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            isFavorite = FavoritesStore.shared.contains(ride.id)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "--" }
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    private func extractRegion(from title: String) -> String? {
        // Simple heuristic to extract region from titles like "Alpine Climb" -> "Alpine"
        let words = title.components(separatedBy: " ")
        return words.count > 1 ? words.dropLast().joined(separator: " ") : nil
    }
}

// MARK: - Apple-style Favorite Button
private struct FavoriteButton: View {
    @Binding var isFav: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isFav.toggle()
                onToggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } label: {
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)          // tap target
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .tint(.pink)                                // Apple uses pink/red for "love"
        .foregroundStyle(isFav ? Color.pink : Color.secondary)
        .accessibilityLabel(isFav ? "Remove from Favorites" : "Add to Favorites")
        .accessibilityAddTraits(isFav ? .isSelected : [])
    }
}

// MARK: - Compact Label Style for Stats
private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon
                .font(.caption2)
            configuration.title
        }
    }
}

// MARK: - Lazy Route Thumbnail
private struct AsyncRouteThumbnail: View {
    let coordinates: [CLLocationCoordinate2D]?
    @State private var thumbnail: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemFill))
                    
                    Image(systemName: "map.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                        .opacity(isLoading ? 0.5 : 1.0)
                }
            }
        }
        .task {
            await loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() async {
        guard let coordinates = coordinates,
              !coordinates.isEmpty,
              thumbnail == nil,
              !isLoading else { return }
        
        isLoading = true
        
        // Use actor-based thumbnail provider with larger size for wide poster preview
        thumbnail = await AsyncRouteThumbnailProvider.shared.thumbnail(
            for: coordinates,
            size: CGSize(width: 300, height: 120)
        )
        
        isLoading = false
    }
}

// MARK: - Route Stats Calculator
enum RouteStatsCalculator {
    static func distance(coords: [CLLocationCoordinate2D]) -> Double {
        guard coords.count > 1 else { return 0 }
        
        var totalDistance: CLLocationDistance = 0
        for i in 1..<coords.count {
            let location1 = CLLocation(latitude: coords[i-1].latitude, longitude: coords[i-1].longitude)
            let location2 = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
            totalDistance += location2.distance(from: location1)
        }
        
        return totalDistance * 0.000621371 // Convert meters to miles
    }
    
    static func elevationGain(coords: [CLLocationCoordinate2D]) -> Double {
        // For demo purposes, estimate based on route length and assume some elevation
        let distance = self.distance(coords: coords)
        return distance * 100 // Rough estimate: 100ft per mile
    }
    
    static func estimatedDuration(coords: [CLLocationCoordinate2D]) -> TimeInterval? {
        let distance = self.distance(coords: coords)
        guard distance > 0 else { return nil }
        
        // Estimate 12 mph average cycling speed
        let hours = distance / 12.0
        return hours * 3600 // Convert to seconds
    }
}

// MARK: - Liquid Glass Container
struct LiquidGlassContainer<Content: View>: View {
    let material: Material
    let content: Content
    
    init(material: Material = .ultraThinMaterial, @ViewBuilder content: () -> Content) {
        self.material = material
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(material)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )
            )
    }
}