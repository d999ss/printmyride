import SwiftUI

struct GalleryView: View {
    @StateObject private var store = PosterStore()
    private let grid = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: grid, spacing: 12) {
                ForEach(store.posters) { poster in
                    PosterCard(poster: poster, imageURL: store.imageURL(for: poster.thumbnailPath))
                }
            }
            .padding(16)
        }
        .navigationTitle("Your Posters")
        .task { await store.bootstrap() } // seeds on first run if asset is present
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