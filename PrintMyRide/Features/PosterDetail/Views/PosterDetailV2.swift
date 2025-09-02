// PrintMyRide/UI/PosterDetailV2.swift - Enhanced with Focus Mode + Fixed Layout
import SwiftUI
import MapKit

// MARK: - Fixed Layout Components

/// Always renders at a fixed paper aspect and keeps overlays inside.
struct PosterPaper<Poster: View, Overlay: View>: View {
    let aspectRatio: CGFloat          // e.g. 18.0/24.0
    let poster: () -> Poster          // your route/map image or vector
    let overlay: () -> Overlay        // metrics bar, stays inside

    var body: some View {
        ZStack {
            poster()
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipped()

            // This overlay is clipped by the poster bounds because it sits in the same ZStack
            overlay()
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle()) // full poster is tappable
        .accessibilityIdentifier("poster")
    }
}

struct MetricsBar: View {
    var distance: String
    var climb: String
    var time: String
    var date: String

    var body: some View {
        HStack(spacing: 10) {
            pill("Distance", distance)
            pill("Climb", climb)
            pill("Time", time)
            pill("Date", date)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
        .lineLimit(1)
        .minimumScaleFactor(0.85)  // gently compress, do not wrap
        .accessibilityIdentifier("metrics")
    }

    private func pill(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.footnote.weight(.semibold))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            Capsule().fill(Color(.secondarySystemBackground).opacity(0.6))
        )
    }
}

@MainActor
final class PosterDetailVM: ObservableObject {
    @Published var generatedImage: UIImage?
    @Published var isGenerating = false
    @Published var toast: String?
    @Published var isFavorite = false
    
    private let favoritesStore = FavoritesStore.shared
    private var posterID: UUID?

    @AppStorage("useOptimizedRenderer") var useOptimizedRenderer = true
    @AppStorage("pmr.useMapBackground") var useMapBackground = true
    @AppStorage("pmr.mapStyle") var mapStyle = 0
    @AppStorage("pmr.units") var units = "mi"
    @AppStorage("pmr.showBuildings") var showBuildings = false
    @AppStorage("pmr.showPointsOfInterest") var showPointsOfInterest = false

    @Published var selectedPreset = 0
    @Published var selectedMapStyle: MapTerrain = .standard
    let presets: [PosterPreset] = [
        .init(name: "Classic", bg: .black, route: .white, stroke: 3),
        .init(name: "Mono", bg: .white, route: .black, stroke: 3),
        .init(name: "Glow", bg: .black, route: .white, stroke: 4, shadow: true),
        .init(name: "Cornsilk", bg: Color(red: 0.98, green: 0.95, blue: 0.87), route: .black, stroke: 3)
    ]

    var distanceMeters: Double = 0
    var elevationMeters: Double = 0
    var durationSec: Double = 0
    var date: Date = Date()

    var coords: [CLLocationCoordinate2D] = []
    var title: String = "Unnamed Ride"
    var subtitle: String = ""

    func render(size: CGSize) async {
        guard !coords.isEmpty else { return }
        isGenerating = true
        defer { isGenerating = false }
        
        if useMapBackground {
            // Generate map-based poster with selected style
            await generateMapPoster(size: size)
        } else {
            // Use the standard poster composition system
            let spec = PosterSpec(ratio: size.height > size.width ? .threeFour : .fourFive, canvas: size)
            
            let metrics = PosterMetrics(
                distance: distanceFormatted,
                elevation: climbFormatted, 
                time: timeFormatted,
                date: dateFormatted
            )
            
            let composer = PosterComposer()
            do {
                let rendered = try await composer.renderPoster(
                    route: coords,
                    title: title,
                    metrics: metrics,
                    spec: spec,
                    scale: 2.0
                )
                generatedImage = rendered
            } catch {
                print("Failed to render poster: \(error)")
                generatedImage = nil
            }
        }
    }
    
    func generateMapPoster(size: CGSize) async {
        // Use MapKitPoster with selected terrain style
        generatedImage = await MapKitPoster.snapshot(
            coords: coords,
            size: size,
            terrain: selectedMapStyle
        )
    }
    
    func saveSnapshot() {
        guard let image = generatedImage,
              let posterID = posterID else { return }
        
        // Create a poster object for saving
        let poster = Poster(
            id: posterID,
            title: title,
            createdAt: date,
            thumbnailPath: "",
            filePath: "",
            coordinateData: nil
        )
        
        // Save to disk and notify
        PosterSnapshotStore.shared.saveSnapshot(image, for: poster)
        toast = "Poster saved!"
    }
    
    // MARK: - Computed properties for display
    var distanceFormatted: String {
        return units == "mi" ? formatDistance(distanceMeters) : formatDistanceKm(distanceMeters)
    }
    
    var climbFormatted: String {
        return units == "mi" ? formatClimb(elevationMeters) : "\(Int(elevationMeters)) m"
    }
    
    var timeFormatted: String {
        return formatTime(durationSec)
    }
    
    var dateFormatted: String {
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var aspectRatio: CGFloat {
        return 18.0/24.0 // Standard poster aspect ratio
    }

    func formatDistance(_ m: Double) -> String {
        let miles = m / 1609.344
        return miles < 0.1 ? "\(Int(m)) m" : String(format: "%.1f mi", miles)
    }
    
    func formatDistanceKm(_ m: Double) -> String {
        let km = m / 1000.0
        return km < 0.1 ? "\(Int(m)) m" : String(format: "%.1f km", km)
    }
    
    func formatClimb(_ m: Double) -> String {
        let ft = m * 3.28084
        return "\(Int(ft)) ft"
    }
    
    func formatTime(_ s: Double) -> String {
        let h = Int(s) / 3600, m = (Int(s) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    func exportPDF() {
        toast = "Export started"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.toast = "PDF saved"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.toast = nil
            }
        }
    }
    
    func saveMapSnapshot() {
        toast = "Map snapshot saved"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.toast = nil
        }
    }
    
    func share() {
        toast = "Sharing poster..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.toast = nil
        }
    }
    
    func printPoster() {
        toast = "Opening print flow..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.toast = nil
        }
    }
    
    func setPosterID(_ id: UUID) {
        posterID = id
        updateFavoriteState()
    }
    
    func toggleFavorite() {
        guard let id = posterID else { return }
        favoritesStore.toggle(id)
        updateFavoriteState()
        toast = isFavorite ? "Added to favorites" : "Removed from favorites"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.toast = nil }
    }
    
    private func updateFavoriteState() {
        guard let id = posterID else { return }
        isFavorite = favoritesStore.contains(id)
    }
}

// MARK: - Enhanced PosterDetailV2 with Focus Mode

struct PosterDetailV2: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PosterDetailVM()

    let posterID: UUID
    let rideTitle: String
    let rideSubtitle: String
    let coords: [CLLocationCoordinate2D]
    let distanceMeters: Double
    let elevationMeters: Double
    let durationSec: Double
    let date: Date

    @State private var isFocused = false
    @Namespace private var posterNS

    init(
        posterID: UUID,
        rideTitle: String,
        rideSubtitle: String = "",
        coords: [CLLocationCoordinate2D],
        distanceMeters: Double = 0,
        elevationMeters: Double = 0,
        durationSec: Double = 0,
        date: Date = .init()
    ) {
        self.posterID = posterID
        self.rideTitle = rideTitle
        self.rideSubtitle = rideSubtitle
        self.coords = coords
        self.distanceMeters = distanceMeters
        self.elevationMeters = elevationMeters
        self.durationSec = durationSec
        self.date = date
    }

    var body: some View {
        ZStack {
            Color.black.opacity(isFocused ? 1 : 0).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: !isFocused) {
                VStack(spacing: isFocused ? 0 : 16) {

                    // POSTER
                    Group {
                        PosterPaper(aspectRatio: vm.aspectRatio) {
                            // Poster content
                            posterView
                                .matchedGeometryEffect(id: "poster", in: posterNS)
                                .cornerRadius(isFocused ? 0 : 12)
                                .shadow(radius: isFocused ? 0 : 8)
                        } overlay: {
                            MetricsBar(
                                distance: vm.distanceFormatted,
                                climb: vm.climbFormatted,
                                time: vm.timeFormatted,
                                date: vm.dateFormatted
                            )
                        }
                        .padding(.horizontal, isFocused ? 0 : 16)
                        .onTapGesture {
                            if vm.generatedImage != nil {
                                withAnimation(.snappy(duration: 0.22)) { isFocused.toggle() }
                            }
                        }
                    }

                    // CONTROLS (hidden in focus)
                    if !isFocused {
                        actionsGrid
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        mapOptionsSection
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                        presetsStrip
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }
                }
                .padding(.top, isFocused ? 0 : 16)
            }
            .statusBarHidden(isFocused)
            .toolbar(isFocused ? .hidden : .visible, for: .navigationBar, .tabBar)
            
            // Toast overlay
            if let toast = vm.toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Close button that respects safe area when focused
        .safeAreaInset(edge: .top) {
            if isFocused {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.snappy(duration: 0.22)) { isFocused = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(radius: 8)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.top, 4)
                .background(.clear)
            }
        }
        .navigationTitle(rideTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.coords = coords
            vm.distanceMeters = distanceMeters
            vm.elevationMeters = elevationMeters
            vm.durationSec = durationSec
            vm.date = date
            vm.title = rideTitle
            vm.subtitle = rideSubtitle
            vm.setPosterID(posterID)
            await vm.render(size: CGSize(width: 1200, height: 1600))
        }
        .task(id: vm.selectedPreset) {
            await vm.render(size: CGSize(width: 1200, height: 1600))
        }
    }
    
    @ViewBuilder
    private var posterView: some View {
        if let posterImage = vm.generatedImage {
            Image(uiImage: posterImage)
                .resizable()
        } else if vm.isGenerating {
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .overlay(
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Generating poster...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                )
        } else {
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .overlay(
                    Button("Generate Poster") {
                        Task { await vm.render(size: CGSize(width: 1200, height: 1600)) }
                    }
                    .buttonStyle(.borderedProminent)
                )
        }
    }

    // MARK: - Actions

    private var actionsGrid: some View {
        HStack(spacing: 12) {
            // Left side - main actions
            HStack(spacing: 12) {
                action("Export", system: "square.and.arrow.up") { vm.exportPDF() }
                action("Print", system: "printer") { vm.printPoster() }
                action("Share", system: "square.and.arrow.up") { vm.share() }
            }
            
            Spacer()
            
            // Right side - favorite
            Button {
                vm.toggleFavorite()
            } label: {
                Image(systemName: vm.isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundStyle(vm.isFavorite ? .red : .primary)
            }
        }
        .padding(.bottom, 6)
    }

    private func action(_ title: String, system: String, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            VStack(spacing: 6) {
                Image(systemName: system).font(.title3.weight(.semibold))
                Text(title).font(.footnote.weight(.semibold))
            }
            .frame(width: 80, height: 56)
        }
        .buttonStyle(.borderedProminent)
        .labelStyle(.iconOnly) // forces single line text below icon
    }

    private var mapOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Map Background Toggle
            Toggle("Use Map Background", isOn: $vm.useMapBackground)
                .font(.headline)
                .onChange(of: vm.useMapBackground) { _ in
                    Task { await vm.render(size: CGSize(width: 1200, height: 1600)) }
                }
            
            if vm.useMapBackground {
                // Map Style Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Map Style")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    Picker("Map Style", selection: $vm.selectedMapStyle) {
                        ForEach(MapTerrain.allCases) { terrain in
                            Text(terrain.label).tag(terrain)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: vm.selectedMapStyle) { _ in
                        Task { await vm.render(size: CGSize(width: 1200, height: 1600)) }
                    }
                }
                
                // Additional Map Options
                VStack(spacing: 12) {
                    Toggle("Show Buildings", isOn: $vm.showBuildings)
                        .font(.subheadline)
                        .onChange(of: vm.showBuildings) { _ in
                            Task { await vm.render(size: CGSize(width: 1200, height: 1600)) }
                        }
                    
                    Toggle("Show Points of Interest", isOn: $vm.showPointsOfInterest)
                        .font(.subheadline)
                        .onChange(of: vm.showPointsOfInterest) { _ in
                            Task { await vm.render(size: CGSize(width: 1200, height: 1600)) }
                        }
                }
                
                // Save Snapshot Button
                Button(action: { vm.saveSnapshot() }) {
                    Label("Save Map Snapshot", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
            }
            
            Divider()
        }
    }
    
    private var presetsStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style Presets").font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.presets.indices, id: \.self) { index in
                        PresetCard(
                            preset: vm.presets[index], 
                            isSelected: vm.selectedPreset == index
                        ) {
                            vm.selectedPreset = index
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            HStack {
                Text("Paper")
                Spacer()
                Text("18×24 • \(vm.presets[vm.selectedPreset].name)")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }
    
    struct PresetCard: View {
        let preset: PosterPreset
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(preset.bg)
                    .frame(width: 60, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(preset.route, lineWidth: 2)
                            .padding(8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? .orange : .clear, lineWidth: 2)
                    )
                
                Text(preset.name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .onTapGesture { action() }
        }
    }
}

// MARK: - Supporting Types

struct PosterPreset: Hashable {
    let name: String
    let bg: Color
    let route: Color
    let stroke: CGFloat
    var shadow: Bool = false
}


