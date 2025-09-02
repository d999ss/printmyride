import Foundation

struct PosterText: Codable, Equatable {
    var title: String = "My Ride"
    var subtitle: String = ""
    var showDistance: Bool = true
    var showElevation: Bool = false
    var showDate: Bool = true
    var titleSizePt: Double = 28
}