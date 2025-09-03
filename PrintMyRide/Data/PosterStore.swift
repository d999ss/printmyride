import Foundation
import UIKit

@MainActor
final class PosterStore: ObservableObject {
    static let shared = PosterStore()
    
    @Published private(set) var posters: [Poster] = []

    private let seededKey = "pmr.hasSeededSamplePoster"
    private let indexFile = "posters_index.json"

    // MARK: Public API
    func bootstrap() async {
        loadIndex()
        if posters.isEmpty && !UserDefaults.standard.bool(forKey: seededKey) {
            await seedSampleIfNeeded()
        }
    }

    func add(_ poster: Poster) {
        posters.insert(poster, at: 0)
        saveIndex()
    }
    
    func add(_ poster: Poster, image: UIImage) async throws {
        let thumbFile = "\(poster.id.uuidString)_thumb.jpg"
        let fullFile = "\(poster.id.uuidString)_full.jpg"
        
        // Create thumbnail
        let thumb = await resized(image: image, maxDimension: 600)
        try writeJPEG(thumb, name: thumbFile, quality: 0.9)
        try writeJPEG(image, name: fullFile, quality: 0.98)
        
        // Update poster with file paths
        let updatedPoster = Poster(
            id: poster.id,
            title: poster.title,
            createdAt: poster.createdAt,
            thumbnailPath: thumbFile,
            filePath: fullFile
        )
        
        posters.insert(updatedPoster, at: 0)
        saveIndex()
    }

    // MARK: Seeding
    private func seedSampleIfNeeded() async {
        // If the bundle asset doesn't exist, quietly skip seeding.
        guard let sampleImage = UIImage(named: "SamplePoster") else { return }

        let thumbFile = "sample_poster_thumb.jpg"
        let fullFile  = "sample_poster_full.jpg"   // use .pdf in future if desired

        do {
            // Create a smaller thumbnail
            let thumb = await resized(image: sampleImage, maxDimension: 600)
            try writeJPEG(thumb, name: thumbFile, quality: 0.9)
            try writeJPEG(sampleImage, name: fullFile, quality: 0.98)

            let sample = Poster.sample(
                title: "Park City Loop",
                thumbName: thumbFile,
                fileName: fullFile
            )
            posters = [sample]
            saveIndex()
            UserDefaults.standard.set(true, forKey: seededKey)
        } catch {
            // Non-critical; do not crash
            print("Seeding failed: \(error)")
        }
    }

    // MARK: Persistence
    private func loadIndex() {
        let url = documentsURL().appendingPathComponent(indexFile)
        guard let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode([Poster].self, from: data) {
            posters = decoded
        }
    }

    private func saveIndex() {
        let url = documentsURL().appendingPathComponent(indexFile)
        do {
            let data = try JSONEncoder().encode(posters)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Save index failed: \(error)")
        }
    }

    // MARK: Utilities
    private func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func writeJPEG(_ image: UIImage, name: String, quality: CGFloat) throws {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw NSError(domain: "pmr.jpeg.encode", code: -1)
        }
        let url = documentsURL().appendingPathComponent(name)
        try data.write(to: url, options: [.atomic])
    }

    private func resized(image: UIImage, maxDimension: CGFloat) async -> UIImage {
        let scale = max(image.size.width, image.size.height) / maxDimension
        guard scale > 1 else { return image }
        let newSize = CGSize(width: image.size.width/scale, height: image.size.height/scale)

        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let format = UIGraphicsImageRendererFormat.default()
                format.scale = 1
                let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
                let img = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                }
                cont.resume(returning: img)
            }
        }
    }

    // Public helper for URL from relative path
    func imageURL(for relativePath: String) -> URL {
        documentsURL().appendingPathComponent(relativePath)
    }
}