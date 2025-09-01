import Foundation
import CoreLocation

struct Poster: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var createdAt: Date
    var thumbnailPath: String   // relative path in Documents
    var filePath: String        // relative path in Documents (PDF/JPG)
    var coordinateData: Data?  // Encoded GPS route data
    
    // Computed property to decode coordinates
    var coordinates: [CLLocationCoordinate2D]? {
        get {
            guard let data = coordinateData else { return nil }
            return try? JSONDecoder().decode([SerializableCoordinate].self, from: data).map { $0.coordinate }
        }
        set {
            coordinateData = newValue?.compactMap { SerializableCoordinate(coordinate: $0) }.data
        }
    }

    static func sample(title: String, thumbName: String, fileName: String) -> Poster {
        Poster(
            id: UUID(),
            title: title,
            createdAt: Date(),
            thumbnailPath: thumbName,
            filePath: fileName,
            coordinateData: nil
        )
    }
}

// Helper struct to make CLLocationCoordinate2D Codable
struct SerializableCoordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

extension Array where Element == SerializableCoordinate {
    var data: Data? {
        try? JSONEncoder().encode(self)
    }
}