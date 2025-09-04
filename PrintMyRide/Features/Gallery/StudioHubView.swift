import SwiftUI

struct StudioHubView: View {
    @State private var selectedRide: Poster?
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        VStack(spacing: 20) {
            // Studio welcome header
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("Poster Studio")
                    .font(.largeTitle.bold())
                
                Text("Transform your rides into art")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            
            // Main CTAs
            VStack(spacing: 16) {
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
                
                Button {
                    // Create from template
                } label: {
                    Label("Browse Templates", systemImage: "rectangle.grid.2x2")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.bordered)
                
                Button {
                    // Import GPX
                } label: {
                    Label("Import GPX File", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Studio")
        .onReceive(NotificationCenter.default.publisher(for: .pmrStudioRideSelected)) { notification in
            if let poster = notification.object as? Poster {
                selectedRide = poster
                // Switch to Studio tab
                router.selectedTab = 0
            }
        }
    }
}