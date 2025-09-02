import SwiftUI

// MARK: - Poster model helpers
extension Poster {
    /// File name you want to use for this poster's snapshot on disk
    var snapshotFilename: String {
        // Use the title as a stable slug, fallback to id
        let base = title.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
        return "\(base)_\(id.uuidString.prefix(8)).png"
    }
    
    /// Optional key to map to a bundled placeholder (place your files with these names)
    var placeholderKey: String {
        // Map a few known demos; fallback to generic
        switch title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "alpine climb":       return "alpine_climb"
        case "forest switchbacks": return "forest_switchbacks"
        case "coastal sprint":     return "coastal_sprint"
        case "city night ride":    return "city_night_ride"
        default:                   return "poster_placeholder" // generic fallback
        }
    }
    
    /// Check if poster is favorited using FavoritesStore
    @MainActor var isFavorite: Bool {
        return FavoritesStore.shared.contains(id)
    }
}

// MARK: - Paths
enum SnapshotPaths {
    static var appSupportDir: URL = {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = url.appendingPathComponent("PosterSnapshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    static func snapshotURL(for filename: String) -> URL {
        appSupportDir.appendingPathComponent(filename, conformingTo: .png)
    }
}

// MARK: - Snapshot Store
struct PosterSnapshotStore {
    static let shared = PosterSnapshotStore()
    
    /// Read a saved snapshot image from disk (if exists)
    func loadSnapshot(for poster: Poster) -> UIImage? {
        let url = SnapshotPaths.snapshotURL(for: poster.snapshotFilename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    
    /// Read a saved snapshot image from disk by filename (if exists)
    static func loadSnapshot(named filename: String) -> UIImage? {
        let url = SnapshotPaths.snapshotURL(for: filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    
    /// Save a UIImage snapshot to disk (PNG)
    func saveSnapshot(_ image: UIImage, for poster: Poster) {
        let url = SnapshotPaths.snapshotURL(for: poster.snapshotFilename)
        if let data = image.pngData() {
            try? data.write(to: url, options: .atomic)
            // Post notification that snapshots changed
            NotificationCenter.default.post(name: .posterSnapshotsDidChange, object: poster.id)
        }
    }
    
    /// Save a UIImage snapshot to disk (PNG) by filename
    static func saveSnapshot(_ image: UIImage, named filename: String) {
        let url = SnapshotPaths.snapshotURL(for: filename)
        if let data = image.pngData() {
            try? data.write(to: url, options: .atomic)
        }
    }
}

// MARK: - Bundled placeholders
enum PlaceholderPosters {
    /// Folder you dragged into Xcode: "PlaceholderPosters"
    /// Ensure "Add to targets: ✅ YourApp" and "Create folder references" OR a file group.
    static let bundleFolder = "PlaceholderPosters"
    
    /// Get the placeholder name for a poster
    static func name(for poster: Poster) -> String {
        return poster.placeholderKey
    }
    
    /// Try to load by exact name first (e.g., "alpine_climb")
    static func image(for key: String) -> UIImage? {
        // Try direct asset catalog loading first
        if let nameHit = UIImage(named: key) { return nameHit }
        
        // Try with common extensions  
        if let pngHit = UIImage(named: "\(key).png") { return pngHit }
        if let jpgHit = UIImage(named: "\(key).jpg") { return jpgHit }
        
        // Also try namespaced path if you kept the folder as a blue folder ref:
        if let path = Bundle.main.path(forResource: key, ofType: "png", inDirectory: bundleFolder) {
            return UIImage(contentsOfFile: path)
        }
        if let path = Bundle.main.path(forResource: key, ofType: "jpg", inDirectory: bundleFolder) {
            return UIImage(contentsOfFile: path)
        }
        
        // Generic fallback
        if let generic = UIImage(named: "poster_placeholder") { return generic }
        if let path = Bundle.main.path(forResource: "poster_placeholder", ofType: "png", inDirectory: bundleFolder) {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
    
    /// Optional: copy placeholders into app storage on first launch (useful for debug/sharing)
    static func seedIntoAppSupportIfNeeded() {
        let seededFlag = SnapshotPaths.appSupportDir.appendingPathComponent(".seeded")
        guard !FileManager.default.fileExists(atPath: seededFlag.path) else { return }
        
        let fm = FileManager.default
        guard let folderURL = Bundle.main.resourceURL?.appendingPathComponent(bundleFolder, isDirectory: true),
              let contents = try? fm.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) else { return }
        
        for file in contents where ["png","jpg","jpeg"].contains(file.pathExtension.lowercased()) {
            let dest = SnapshotPaths.appSupportDir.appendingPathComponent(file.lastPathComponent)
            if !fm.fileExists(atPath: dest.path) {
                try? fm.copyItem(at: file, to: dest)
            }
        }
        try? "ok".data(using: .utf8)?.write(to: seededFlag)
    }
}

// MARK: - SwiftUI helper view for a poster tile
struct PosterTile: View {
    let poster: Poster
    
    var snapshotOrPlaceholder: UIImage? {
        // 1) try disk snapshot
        if let snap = PosterSnapshotStore.loadSnapshot(named: poster.snapshotFilename) {
            return snap
        }
        // 2) fallback to bundled placeholder
        return PlaceholderPosters.image(for: poster.placeholderKey)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let ui = snapshotOrPlaceholder {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 220)
                    .clipped()
            } else {
                // Last-ditch white card so nothing is blank
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 160, height: 220)
            }
            
            HStack(spacing: 8) {
                Button { sharePoster(poster) } label: {
                    Image(systemName: "square.and.arrow.up")
                        .padding(6).background(.black.opacity(0.6)).clipShape(Circle())
                }
                Button { 
                    Task { @MainActor in
                        toggleFavorite(poster) 
                    }
                } label: {
                    Image(systemName: poster.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                        .padding(6).background(.black.opacity(0.6)).clipShape(Circle())
                }
            }
            .padding(8)
        }
        .cornerRadius(12)
        .shadow(radius: 3)
        .accessibilityLabel(Text(poster.title))
    }
    
    private func sharePoster(_ poster: Poster) {
        guard let image = snapshotOrPlaceholder else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    @MainActor private func toggleFavorite(_ poster: Poster) {
        FavoritesStore.shared.toggle(poster.id)
    }
}

// MARK: - App Bootstrap
final class AppBootstrap {
    static func run() {
        PlaceholderPosters.seedIntoAppSupportIfNeeded()
    }
}