// PrintMyRide/UI/PosterDetail/Components/StatisticsGrid.swift
import SwiftUI

struct StatisticsGrid: View {
    let rideData: RideData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ride Statistics")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                StatTile(
                    title: "Distance",
                    value: formatDistance(rideData.distanceMeters),
                    icon: "road.lanes"
                )
                
                StatTile(
                    title: "Elevation",
                    value: formatElevation(rideData.elevationMeters),
                    icon: "mountain.2"
                )
                
                StatTile(
                    title: "Duration",
                    value: formatDuration(rideData.durationSeconds),
                    icon: "clock"
                )
                
                StatTile(
                    title: "Date",
                    value: rideData.date.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar"
                )
                
                StatTile(
                    title: "Avg Pace",
                    value: calculatePace(
                        distance: rideData.distanceMeters,
                        duration: rideData.durationSeconds
                    ),
                    icon: "speedometer"
                )
                
                StatTile(
                    title: "Points",
                    value: "\(rideData.coordinates.count)",
                    icon: "point.3.connected.trianglepath.dotted"
                )
            }
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let miles = meters / 1609.344
        return miles < 0.1 ? "\(Int(meters)) m" : String(format: "%.1f mi", miles)
    }
    
    private func formatElevation(_ meters: Double) -> String {
        let feet = meters * 3.28084
        return "\(Int(feet)) ft"
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func calculatePace(distance: Double, duration: Double) -> String {
        guard distance > 0, duration > 0 else { return "—" }
        
        let miles = distance / 1609.344
        let secondsPerMile = duration / miles
        let minutesPerMile = Int(secondsPerMile) / 60
        let secondsRemainder = Int(secondsPerMile) % 60
        
        return "\(minutesPerMile):\(String(format: "%02d", secondsRemainder))/mi"
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    StatisticsGrid(
        rideData: RideData(
            title: "Morning Ride",
            distanceMeters: 32180, // ~20 miles
            elevationMeters: 500,   // ~1640 feet
            durationSeconds: 3600,  // 1 hour
            date: Date()
        )
    )
    .padding()
}