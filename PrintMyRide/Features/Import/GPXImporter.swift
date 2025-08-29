import Foundation

final class GPXImporter: NSObject, XMLParserDelegate {
    private var points: [GPXRoute.Point] = []
    private var pendingLat: Double?
    private var pendingLon: Double?
    private var pendingEle: Double?
    private var pendingTime: Date?
    private var textBuffer: String = ""
    private let iso = ISO8601DateFormatter()
    
    static func load(url: URL) -> GPXRoute? {
        guard let data = try? Data(contentsOf: url),
              let route = try? GPXImporter().parse(data: data) else {
            return nil
        }
        return route
    }
    
    func parse(data: Data) throws -> GPXRoute {
        points.removeAll()
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else { throw parser.parserError ?? NSError(domain: "GPX", code: 1) }
        
        let dist = zip(points, points.dropFirst()).reduce(0.0) { $0 + haversine($1.0, $1.1) }
        let duration = if let s = points.first?.t, let e = points.last?.t { e.timeIntervalSince(s) } else { nil as TimeInterval? }
        
        return GPXRoute(points: points, distanceMeters: dist, duration: duration)
    }
    
    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName qName: String?, attributes: [String: String] = [:]) {
        textBuffer.removeAll(keepingCapacity: true)
        
        if name == "trkpt" {
            pendingLat = Double(attributes["lat"] ?? "")
            pendingLon = Double(attributes["lon"] ?? "")
            pendingEle = nil
            pendingTime = nil
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer.append(string)
    }
    
    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmed = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch name {
        case "ele":
            pendingEle = Double(trimmed)
        case "time":
            pendingTime = iso.date(from: trimmed)
        case "trkpt":
            if let la = pendingLat, let lo = pendingLon {
                points.append(.init(lat: la, lon: lo, ele: pendingEle, t: pendingTime))
            }
        default:
            break
        }
        
        textBuffer.removeAll(keepingCapacity: true)
    }
}

func haversine(_ a: GPXRoute.Point, _ b: GPXRoute.Point) -> Double {
    let R = 6_371_000.0
    let φ1 = a.lat * .pi / 180, φ2 = b.lat * .pi / 180
    let dφ = (b.lat - a.lat) * .pi / 180
    let dλ = (b.lon - a.lon) * .pi / 180
    
    let h = sin(dφ/2)*sin(dφ/2) + cos(φ1)*cos(φ2)*sin(dλ/2)*sin(dλ/2)
    return 2 * R * atan2(sqrt(h), sqrt(1 - h))
}
