import SwiftUI

final class LibraryStore: ObservableObject {
    @Published var projects: [PosterProject] = []
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    private let fm = FileManager.default
    private var docs: URL { fm.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    private var thumbsDir: URL { docs.appendingPathComponent("Thumbnails", isDirectory: true) }
    private var dbPath: URL { docs.appendingPathComponent("library.json") }

    init() { load() }

    func load() {
        try? fm.createDirectory(at: thumbsDir, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: dbPath),
           let decoded = try? JSONDecoder().decode([PosterProject].self, from: data) {
            projects = decoded
        } else {
            projects = [] // Start clean - shimmer placeholders will show in Home
        }
    }

    func save() {
        let data = (try? JSONEncoder().encode(projects)) ?? Data()
        try? data.write(to: dbPath, options: .atomic)
    }

    func add(design: PosterDesign, routeURL: URL?, thumbnailPNG: Data,
             title: String = "My Ride", text: PosterText = .init()) {
        let thumbName = "thumb-\(UUID().uuidString).png"
        let thumbURL = thumbsDir.appendingPathComponent(thumbName)
        try? thumbnailPNG.write(to: thumbURL)
        var routeFilename: String? = nil
        if let u = routeURL { routeFilename = copyIn(url: u) }
        let p = PosterProject(title: title, design: design,
                              routeFilename: routeFilename,
                              thumbnailFilename: thumbName,
                              text: text)
        projects.insert(p, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) { projects.remove(atOffsets: offsets); save() }

    func thumbnailURL(for p: PosterProject) -> URL { thumbsDir.appendingPathComponent(p.thumbnailFilename) }

    func routeURL(for p: PosterProject) -> URL? {
        guard let name = p.routeFilename else { return nil }
        return docs.appendingPathComponent(name)
    }

    private func copyIn(url: URL) -> String {
        let name = "route-\(UUID().uuidString).gpx"
        let dest = docs.appendingPathComponent(name)
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        try? fm.removeItem(at: dest)
        try? fm.copyItem(at: url, to: dest)
        return name
    }

    var count: Int { projects.count }
}