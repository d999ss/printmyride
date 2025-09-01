import SwiftUI
import CoreLocation

struct ImportRidesView: View {
    @EnvironmentObject var services: ServiceHub
    @EnvironmentObject var posterStore: PosterStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var rides: [StravaRide] = []
    @State private var isLoading = false
    @State private var selectedRideIds: Set<String> = []
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Loading rides...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if rides.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bicycle.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No rides found")
                            .font(.headline)
                        Text("Connect to Strava to import your rides")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ridesList
                }
            }
            .navigationTitle("Import Rides")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import") {
                        Task { await importSelectedRides() }
                    }
                    .disabled(selectedRideIds.isEmpty || isImporting)
                }
            }
            .task {
                await loadRides()
            }
            .alert("Import Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
            .overlay {
                if isImporting {
                    importProgressOverlay
                }
            }
        }
    }
    
    private var ridesList: some View {
        List {
            Section {
                ForEach(rides, id: \.id) { ride in
                    RideRow(
                        ride: ride,
                        isSelected: selectedRideIds.contains(ride.id)
                    ) {
                        if selectedRideIds.contains(ride.id) {
                            selectedRideIds.remove(ride.id)
                        } else {
                            selectedRideIds.insert(ride.id)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Recent Rides")
                    Spacer()
                    if selectedRideIds.count > 0 {
                        Text("\(selectedRideIds.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var importProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: importProgress)
                    .frame(width: 200)
                
                Text("Importing rides...")
                    .font(.headline)
                
                Text("\(Int(importProgress * Double(selectedRideIds.count)))/\(selectedRideIds.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(30)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private func loadRides() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            rides = try await services.strava.listRecentRides(limit: 20)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func importSelectedRides() async {
        guard !selectedRideIds.isEmpty else { return }
        
        isImporting = true
        importProgress = 0
        defer { isImporting = false }
        
        let selectedRides = rides.filter { selectedRideIds.contains($0.id) }
        
        for (index, ride) in selectedRides.enumerated() {
            do {
                try await importRide(ride)
                importProgress = Double(index + 1) / Double(selectedRides.count)
            } catch {
                errorMessage = "Failed to import \(ride.name): \(error.localizedDescription)"
                return
            }
        }
        
        dismiss()
    }
    
    private func importRide(_ ride: StravaRide) async throws {
        // Parse GPX coordinates
        let coordinates = GPXParser.parseCoordinates(from: ride.gpxData ?? "")
        guard !coordinates.isEmpty else {
            throw ImportError.invalidGPXData
        }
        
        // Format ride data
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let distance = String(format: "%.1f mi", ride.distanceMeters * 0.000621371)
        let duration = formatDuration(ride.movingTimeSec)
        let date = formatter.string(from: ride.startDate)
        
        // Render poster
        guard let posterImage = await RouteRenderer.renderPoster(
            coordinates: coordinates,
            title: ride.name,
            distance: distance,
            duration: duration,
            date: date
        ) else {
            throw ImportError.renderingFailed
        }
        
        // Save to poster store
        let poster = Poster(
            id: UUID(),
            title: ride.name,
            createdAt: Date(),
            thumbnailPath: "", // Will be set by posterStore.add
            filePath: ""       // Will be set by posterStore.add
        )
        
        try await posterStore.add(poster, image: posterImage)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct RideRow: View {
    let ride: StravaRide
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ride.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 16) {
                    Label("\(String(format: "%.1f", ride.distanceMeters * 0.000621371)) mi", 
                          systemImage: "location")
                    Label(formatDuration(ride.movingTimeSec), 
                          systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Text(ride.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

enum ImportError: LocalizedError {
    case invalidGPXData
    case renderingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidGPXData:
            return "Invalid GPX data"
        case .renderingFailed:
            return "Failed to render poster"
        }
    }
}

#Preview {
    ImportRidesView()
        .environmentObject(ServiceHub())
        .environmentObject(PosterStore())
}