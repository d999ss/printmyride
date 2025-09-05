import SwiftUI
import CoreLocation

struct GalleryView: View {
    @EnvironmentObject var library: LibraryStore

    // selection state
    @State private var isSelecting = false
    @State private var selected: Set<UUID> = []

    // grid
    private let cols: [GridItem] = [
        .init(.flexible(), spacing: 2),
        .init(.flexible(), spacing: 2),
        .init(.flexible(), spacing: 2)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                // STUDIO header row (minimal)
                HStack {
                    Text("STUDIO")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(isSelecting ? "Done" : "Select") {
                        UISelectionFeedbackGenerator().selectionChanged()
                        if isSelecting { selected.removeAll() }
                        isSelecting.toggle()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(library.projects.isEmpty ? 0 : 1)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if library.projects.isEmpty {
                    EmptyState()
                } else {
                    ScrollView {
                        LazyVGrid(columns: cols, spacing: 2) {
                            ForEach(library.projects) { p in
                                NavigationLink(destination: PosterDetailView(poster: convertToPoster(p))) {
                                    Tile(project: p,
                                         image: thumb(for: p),
                                         isSelecting: isSelecting,
                                         isSelected: selected.contains(p.id))
                                }
                                .simultaneousGesture(
                                    TapGesture()
                                        .onEnded { _ in
                                            if isSelecting {
                                                toggle(p.id)
                                            }
                                        }
                                )
                                .onLongPressGesture {
                                    if !isSelecting {
                                        isSelecting = true
                                    }
                                    toggle(p.id)
                                }
                            }
                        }
                        .padding(.horizontal, 0)
                        .padding(.bottom, 80) // room for action bar
                    }
                }
            }

            // Bottom action bar (appears in selection)
            if isSelecting {
                ActionBar(selectedCount: selected.count,
                          onShare: shareSelected,
                          onDelete: deleteSelected)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: selected)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .toolbar(.hidden, for: .navigationBar) // no big title
    }

    // MARK: helpers

    private func toggle(_ id: UUID) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func thumb(for p: PosterProject) -> UIImage? {
        UIImage(contentsOfFile: library.thumbnailURL(for: p).path)
    }

    private func convertToPoster(_ project: PosterProject) -> Poster {
        // Convert PosterProject to Poster for PosterDetailView
        var coordinateData: Data?
        
        // Try to load coordinates from route file if available
        if let routeURL = library.routeURL(for: project) {
            if let gpxRoute = GPXImporter.load(url: routeURL) {
                let coordinates = gpxRoute.points.map { 
                    CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) 
                }
                coordinateData = coordinates.compactMap { SerializableCoordinate(coordinate: $0) }.data
            }
        }
        
        return Poster(
            id: project.id,
            title: project.title,
            createdAt: project.createdAt,
            thumbnailPath: project.thumbnailFilename,
            filePath: project.thumbnailFilename, // Use thumbnail as file path since we don't have full res yet
            coordinateData: coordinateData
        )
    }

    private func shareSelected() {
        guard !selected.isEmpty else { return }
        let images: [UIImage] = library.projects
            .filter { selected.contains($0.id) }
            .compactMap { UIImage(contentsOfFile: library.thumbnailURL(for: $0).path) }
        ShareSheet.present(items: images)
    }

    private func deleteSelected() {
        guard !selected.isEmpty else { return }
        let ids = selected
        library.projects.removeAll { ids.contains($0.id) }
        library.save()
        selected.removeAll()
        isSelecting = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Tile (no rounding, no shadows)

private struct Tile: View {
    let project: PosterProject
    let image: UIImage?
    let isSelecting: Bool
    let isSelected: Bool

    var body: some View {
        GeometryReader { geo in
            // 3:4 aspect tile
            let w = geo.size.width
            let h = w * 4.0 / 3.0
            ZStack(alignment: .topTrailing) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()                    // hard edge, no rounding
                } else {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: w, height: h)
                }

                if isSelecting {
                    Circle()
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.35), lineWidth: 2)
                        .background(Circle().fill(isSelected ? Color.white : .clear))
                        .frame(width: 22, height: 22)
                        .padding(6)
                }
            }
            .frame(width: w, height: h)
        }
        .frame(height: tileHeight) // fixes LazyVGrid row height
    }

    private var tileHeight: CGFloat { UIScreen.main.bounds.width/3 * 4/3 }
}

// MARK: - Bottom action bar (monochrome, no shadow)

private struct ActionBar: View {
    let selectedCount: Int
    let onShare: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            Text("\(selectedCount) selected")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Button(action: onShare) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white)
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Empty state (studio vibe)

private struct EmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("No posters yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text("Import a GPX or try a sample from Home.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}