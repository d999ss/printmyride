import Foundation

enum SampleRoute {
    private static var cached: GPXRoute?

    static func route() -> GPXRoute? {
        if let r = cached { return r }
        guard let url = Bundle.main.url(forResource: "default", withExtension: "gpx") else { return nil }
        let r = GPXImporter.load(url: url)
        cached = r
        return r
    }
}