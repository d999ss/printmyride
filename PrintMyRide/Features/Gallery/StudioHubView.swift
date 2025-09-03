import SwiftUI

struct StudioHubView: View {
    @State private var selectedRide: Poster?
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        Group {
            if let selectedRide = selectedRide {
                // Show editor with selected ride
                PosterDetailView(poster: selectedRide)
                    .navigationBarBackButtonHidden(false)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Back to Rides") {
                                self.selectedRide = nil
                            }
                        }
                    }
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
        .onChange(of: router.selectedTab) { newTab in
            // Clear selected ride when switching away from Studio tab
            if newTab != 0 {
                selectedRide = nil
            }
        }
    }
}