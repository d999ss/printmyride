import Foundation

struct Poster: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var createdAt: Date
    var thumbnailPath: String   // relative path in Documents
    var filePath: String        // relative path in Documents (PDF/JPG)

    static func sample(title: String, thumbName: String, fileName: String) -> Poster {
        Poster(
            id: UUID(),
            title: title,
            createdAt: Date(),
            thumbnailPath: thumbName,
            filePath: fileName
        )
    }
}