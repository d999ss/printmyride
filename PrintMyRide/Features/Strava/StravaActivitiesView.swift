import SwiftUI

struct StravaActivitiesView: View {
    @StateObject private var stravaService = MultiUserStravaService.shared
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if stravaService.isLoading && stravaService.activities.isEmpty {
                    loadingView
                } else if stravaService.activities.isEmpty {
                    emptyView
                } else {
                    activitiesListView
                }
            }
            .navigationTitle("Your Rides")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !stravaService.activities.isEmpty {
                        Button(stravaService.selectedActivities.isEmpty ? "Select All" : "Deselect All") {
                            if stravaService.selectedActivities.isEmpty {
                                stravaService.selectAll()
                            } else {
                                stravaService.deselectAll()
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            .task {
                await loadActivities()
            }
            .refreshable {
                await loadActivities()
            }
        }
        .sheet(isPresented: $showExportSheet) {
            exportSheet
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading your rides...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bicycle.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No rides found")
                    .font(.headline)
                
                Text("Your Strava activities will appear here")
                    .foregroundColor(.secondary)
            }
            
            Button("Refresh") {
                Task { await loadActivities() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder
    private var activitiesListView: some View {
        VStack(spacing: 0) {
            // Selection summary and export button
            if !stravaService.selectedActivities.isEmpty {
                HStack {
                    Text(stravaService.selectionSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Export GPX") {
                        exportSelectedActivities()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }
            
            List {
                ForEach(stravaService.activities) { activity in
                    ActivityRowView(
                        activity: activity,
                        isSelected: stravaService.selectedActivities.contains(activity.id)
                    ) {
                        stravaService.toggleSelection(for: activity.id)
                    }
                }
            }
            .listStyle(.plain)
        }
        
        if let errorMessage = errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .padding()
        }
    }
    
    @ViewBuilder
    private var exportSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.zipper")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Export Successful!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your GPX files have been exported and are ready to share.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if let exportURL = exportURL {
                    ShareLink(item: exportURL) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share ZIP File")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Button("Done") {
                    showExportSheet = false
                }
                .foregroundColor(.accentColor)
            }
            .padding()
            .navigationTitle("Export Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showExportSheet = false
                    }
                }
            }
        }
    }
    
    private func loadActivities() async {
        do {
            try await stravaService.fetchActivities()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func exportSelectedActivities() {
        Task {
            do {
                let url = try await stravaService.exportSelectedActivities()
                await MainActor.run {
                    exportURL = url
                    showExportSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ActivityRowView: View {
    let activity: StravaActivity
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            // Selection indicator
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(activity.startDateFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label(activity.distanceFormatted, systemImage: "location")
                    
                    Label(activity.movingTimeFormatted, systemImage: "clock")
                    
                    if let elevation = activity.elev_gain_m, elevation > 0 {
                        Label("\(Int(elevation))m", systemImage: "mountain.2")
                    }
                    
                    Spacer()
                    
                    Text(activity.type)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

#Preview {
    StravaActivitiesView()
}