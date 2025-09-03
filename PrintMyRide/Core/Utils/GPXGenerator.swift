import Foundation
import CoreLocation

struct GPXGenerator {
    static func generate(
        coordinates: [CLLocationCoordinate2D],
        title: String,
        description: String
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let timestamp = formatter.string(from: Date())
        
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="PrintMyRide" xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(title.isEmpty ? "Ride" : title)</name>
            <desc>\(description)</desc>
            <time>\(timestamp)</time>
          </metadata>
          <trk>
            <name>\(title.isEmpty ? "Ride" : title)</name>
            <trkseg>
        
        """
        
        for coord in coordinates {
            gpx += "      <trkpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\"></trkpt>\n"
        }
        
        gpx += """
            </trkseg>
          </trk>
        </gpx>
        """
        
        return gpx
    }
}