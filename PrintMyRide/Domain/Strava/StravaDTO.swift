import Foundation

struct StravaActivityDTO: Decodable {
    let id: Int
    let name: String
    let distance: Double
    let moving_time: Int
    let start_date: String
}

struct StravaStreamsDTO: Decodable {
    struct LatLngStream: Decodable { let data: [[Double]]? }
    let latlng: LatLngStream?
}