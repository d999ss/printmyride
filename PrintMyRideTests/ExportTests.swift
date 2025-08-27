import XCTest
@testable import PrintMyRide

final class ExportTests: XCTestCase {
    func testExportDimensions() throws {
        let pts = [
            GPXRoute.Point(lat: 37.0, lon: -122.0, ele: nil, t: nil),
            GPXRoute.Point(lat: 37.01, lon: -122.0, ele: nil, t: nil),
            GPXRoute.Point(lat: 37.01, lon: -121.99, ele: nil, t: nil)
        ]
        let route = GPXRoute(points: pts, distanceMeters: 0, duration: nil)
        var design = PosterDesign()
        design.widthInches = 18
        design.heightInches = 24
        design.dpi = 300
        
        let data = PosterExport.renderPNG(route: route, design: design, exportScale: 1.0)
        XCTAssertNotNil(data)
        
        let img = UIImage(data: data!)!
        XCTAssertEqual(img.size.width, 5400, accuracy: 1)
        XCTAssertEqual(img.size.height, 7200, accuracy: 1)
    }
}