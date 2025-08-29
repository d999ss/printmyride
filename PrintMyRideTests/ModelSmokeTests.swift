import XCTest
@testable import PrintMyRide

final class ModelSmokeTests: XCTestCase {
    func testPosterDesignIsVisible() {
        _ = PosterDesign(showGrid: true)
    }
    
    func testColorDataIsVisible() {
        _ = PosterDesign.ColorData(.black)
    }
    
    func testGPXRouteIsVisible() {
        let points = [GPXRoute.Point(lat: 0, lon: 0)]
        _ = GPXRoute(points: points, distanceMeters: 0, duration: nil)
    }
}