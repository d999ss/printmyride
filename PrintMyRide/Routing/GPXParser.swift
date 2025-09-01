import Foundation
import CoreLocation

struct GPXParser {
    static func parseCoordinates(from gpxData: Data) -> [CLLocationCoordinate2D] {
        guard String(data: gpxData, encoding: .utf8) != nil else { return [] }
        
        var coordinates: [CLLocationCoordinate2D] = []
        let parser = XMLParser(data: gpxData)
        let delegate = GPXParserDelegate { coord in coordinates.append(coord) }
        parser.delegate = delegate
        parser.parse()
        
        return coordinates
    }
    
    static func parseCoordinates(from gpxString: String) -> [CLLocationCoordinate2D] {
        guard let data = gpxString.data(using: .utf8) else { return [] }
        return parseCoordinates(from: data)
    }
}

private class GPXParserDelegate: NSObject, XMLParserDelegate {
    private let onCoordinate: (CLLocationCoordinate2D) -> Void
    private var currentElement = ""
    private var currentLat: String?
    private var currentLon: String?
    
    init(onCoordinate: @escaping (CLLocationCoordinate2D) -> Void) {
        self.onCoordinate = onCoordinate
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "trkpt" {
            currentLat = attributeDict["lat"]
            currentLon = attributeDict["lon"]
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "trkpt", 
           let latStr = currentLat, let lonStr = currentLon,
           let lat = Double(latStr), let lon = Double(lonStr) {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            onCoordinate(coordinate)
            currentLat = nil
            currentLon = nil
        }
    }
}