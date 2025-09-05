import Foundation

enum ImageSource: Codable, Equatable {
    case url(URL)
    case local(String)
}

struct StorePoster: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let story: String
    let imageSources: [ImageSource]
    let priceCents: Int
    let currency: String
    let variants: [Variant]
    let specs: [Specification]
    
    init(id: UUID = UUID(), title: String, story: String, imageSources: [ImageSource], priceCents: Int, currency: String = "USD", variants: [Variant], specs: [Specification]) {
        self.id = id
        self.title = title
        self.story = story
        self.imageSources = imageSources
        self.priceCents = priceCents
        self.currency = currency
        self.variants = variants
        self.specs = specs
    }
}

struct Variant: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let priceDeltaCents: Int
    
    init(id: UUID = UUID(), name: String, priceDeltaCents: Int = 0) {
        self.id = id
        self.name = name
        self.priceDeltaCents = priceDeltaCents
    }
}

struct Specification: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let value: String
    
    init(id: UUID = UUID(), name: String, value: String) {
        self.id = id
        self.name = name
        self.value = value
    }
}

// MARK: - Sample Data

extension StorePoster {
    static let sample = StorePoster(
        title: "Porsche Carrera GT Track Day",
        story: "Experience the thrill of the legendary Porsche Carrera GT captured at the peak of performance. This exclusive poster series showcases the raw power and engineering excellence of one of the most iconic supercars ever created. Each image tells a story of speed, precision, and automotive artistry. Printed on museum-quality paper with archival inks, this collection celebrates the intersection of motorsport and fine art.",
        imageSources: [
            .local("Otoky-N8-Porsche-Carrera-GT-Type-7-Cevoss-2"),
            .local("Otoky-N8-Porsche-Carrera-GT-Type-7-Cevoss-3"),
            .local("Otoky-N8-Porsche-Carrera-GT-Type-7-Cevoss-4")
        ],
        priceCents: 2999,
        variants: [
            Variant(name: "12\" x 16\" - Unframed"),
            Variant(name: "12\" x 16\" - Black Frame", priceDeltaCents: 1500),
            Variant(name: "16\" x 20\" - Unframed", priceDeltaCents: 1000),
            Variant(name: "16\" x 20\" - Black Frame", priceDeltaCents: 2500),
            Variant(name: "20\" x 24\" - Unframed", priceDeltaCents: 2000),
            Variant(name: "20\" x 24\" - Black Frame", priceDeltaCents: 3500)
        ],
        specs: [
            Specification(name: "Paper", value: "Museum Quality"),
            Specification(name: "Print", value: "Archival Inks"),
            Specification(name: "Frame", value: "Solid Wood"),
            Specification(name: "Matting", value: "Acid-Free"),
            Specification(name: "Glass", value: "UV Protection"),
            Specification(name: "Backing", value: "Foam Core")
        ]
    )
}