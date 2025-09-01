import Foundation
import CoreLocation

enum DemoCoordsLoader {
    static func coords(forTitle title: String) -> [CLLocationCoordinate2D] {
        print("🗺️ DemoCoordsLoader: Loading coords for title: '\(title)'")
        
        // Map known demo titles to bundled GPX files
        let map: [String:String] = [
            "Park City Loop": "Demo_ParkCity",
            "Boulder Canyon Spin": "Demo_Boulder",
            "City Night Ride": "Demo_ParkCity", // Reuse existing GPX
            "Coastal Sprint": "Demo_Boulder", // Reuse existing GPX
            "Forest Switchbacks": "Demo_ParkCity", // Reuse existing GPX
            "Alpine Climb": "Demo_Boulder" // Reuse existing GPX
        ]
        
        guard let name = map[title] else {
            print("🗺️ DemoCoordsLoader: No GPX mapping found for title '\(title)'")
            return []
        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "gpx") else {
            print("🗺️ DemoCoordsLoader: GPX file '\(name).gpx' not found in bundle")
            return []
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("🗺️ DemoCoordsLoader: Failed to read GPX file at \(url)")
            return []
        }
        
        let coordinates = GPXParser.parseCoordinates(from: data)
        print("🗺️ DemoCoordsLoader: Parsed \(coordinates.count) coordinates from \(name).gpx")
        
        return coordinates
    }
}