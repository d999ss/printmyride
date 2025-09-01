import Foundation
import CoreLocation

enum DemoCoordsLoader {
    static func coords(forTitle title: String) -> [CLLocationCoordinate2D] {
        // Map known demo titles to bundled GPX files
        let map: [String:String] = [
            "Park City Loop": "Demo_ParkCity",
            "Boulder Canyon Spin": "Demo_Boulder",
            "City Night Ride": "Demo_ParkCity", // Reuse existing GPX
            "Coastal Sprint": "Demo_Boulder", // Reuse existing GPX
            "Forest Switchbacks": "Demo_ParkCity", // Reuse existing GPX
            "Alpine Climb": "Demo_Boulder" // Reuse existing GPX
        ]
        guard let name = map[title],
              let url = Bundle.main.url(forResource: name, withExtension: "gpx"),
              let data = try? Data(contentsOf: url) else { return [] }
        return GPXParser.parseCoordinates(from: data)
    }
}