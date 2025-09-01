import SwiftUI

struct GalleryView: View {
    @StateObject private var store = PosterStore()
    @StateObject private var subscriptionGate = SubscriptionGate()
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var services: ServiceHub
    @State private var showingImport = false
    private let grid = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: grid, spacing: 12) {
                ForEach(store.posters) { poster in
                    NavigationLink {
                        PosterDetailView(poster: poster)
                            .environmentObject(subscriptionGate)
                    } label: {
                        PosterCard(poster: poster, imageURL: store.imageURL(for: poster.thumbnailPath))
                    }
                }
                
                // Empty state with clear instructions
                if store.posters.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: (services.mockStrava || services.strava.isConnected()) ? "plus" : "figure.walk")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text((services.mockStrava || services.strava.isConnected()) ?
                             "No posters yet — tap the + button to add your first ride." :
                             "Connect Strava or enable Demo Mode to import rides.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(16)
        }
        .navigationTitle("Your Posters")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingImport = true
                } label: {
                    Image(systemName: "plus")
                }
                // Enable import if Strava connected OR Demo Mode on
                .disabled(!(services.mockStrava || services.strava.isConnected()))
                .accessibilityIdentifier("importButton")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingImport) {
            ImportRidesView()
                .environmentObject(services)
                .environmentObject(store)
        }
        .task { 
            await store.bootstrap()
            appState.refreshUnitsFromDefaults()
        } // seeds on first run if asset is present
    }
}

private struct PosterCard: View {
    let poster: Poster
    let imageURL: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    Color.gray.opacity(0.15)
                case .failure:
                    Color.gray.opacity(0.25)
                @unknown default:
                    Color.gray.opacity(0.2)
                }
            }
            .frame(height: 180)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(poster.title)
                .font(.subheadline).fontWeight(.semibold)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Text(poster.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}