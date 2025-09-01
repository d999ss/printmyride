import Foundation

struct PosterProject: Identifiable {
    var id: UUID = .init()
    var title: String
    var createdAt: Date = .init()
    var design: PosterDesign
    var routeFilename: String?
    var thumbnailFilename: String
    var text: PosterText = .init()
}