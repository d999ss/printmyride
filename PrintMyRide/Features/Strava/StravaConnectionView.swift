import SwiftUI

struct StravaConnectionView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showDisconnectAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            if authService.isStravaConnected {
                // Connected state
                connectedView
            } else {
                // Not connected state
                notConnectedView
            }
        }
        .padding()
        .alert("Disconnect Strava", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                Task {
                    try await authService.disconnectStrava()
                }
            }
        } message: {
            Text("This will remove access to your Strava activities and stop syncing new rides.")
        }
    }
    
    @ViewBuilder
    private var connectedView: some View {
        VStack(spacing: 20) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Strava Connected")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let athleteId = authService.athleteId {
                    Text("Athlete ID: \(athleteId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Your rides are now available for import and poster creation")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                NavigationLink(destination: StravaActivitiesView()) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("View Activities")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button("Disconnect Strava") {
                    showDisconnectAlert = true
                }
                .foregroundColor(.red)
            }
        }
    }
    
    @ViewBuilder
    private var notConnectedView: some View {
        VStack(spacing: 20) {
            // Strava logo/icon
            Image(systemName: "figure.outdoor.cycle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Connect to Strava")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Import your rides and create beautiful posters")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                Button(action: connectToStrava) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Image(systemName: "link")
                        Text(authService.isLoading ? "Connecting..." : "Connect to Strava")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(authService.isLoading)
                
                VStack(spacing: 4) {
                    Text("• View and import your rides")
                    Text("• Create posters from your activities")
                    Text("• Export GPX files")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private func connectToStrava() {
        Task {
            do {
                try await authService.connectStrava()
            } catch {
                // Handle error - could show alert
                print("Failed to connect to Strava: \(error)")
            }
        }
    }
}

#Preview {
    NavigationView {
        StravaConnectionView()
    }
}