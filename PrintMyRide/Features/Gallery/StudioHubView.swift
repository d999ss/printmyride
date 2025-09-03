import SwiftUI

struct StudioHubView: View {
    @State private var selectedRide: Poster?
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        Group {
            if let selectedRide = selectedRide {
                // Show editor with selected ride
                PosterDetailView(poster: selectedRide)
            } else {
                // Show ride selector
                RidesListView()
                    .navigationTitle("Select a Ride")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pmrStudioRideSelected)) { notification in
            if let poster = notification.object as? Poster {
                selectedRide = poster
                // Switch to Studio tab
                router.selectedTab = 0
            }
        }
    }
}