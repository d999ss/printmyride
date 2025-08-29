import XCTest
import CoreLocation
@testable import PrintMyRide

final class GPXRouteTests: XCTestCase {

    func testCoordinatesNonEmpty() {
        // Arrange
        let coords = TestRouteFactory.line(count: 20)
        // Act
        XCTAssertFalse(coords.isEmpty)
        // Sanity: endpoints intact
        XCTAssertEqual(coords.first!.latitude,  coords.first!.latitude)
        XCTAssertEqual(coords.last!.longitude,  coords.last!.longitude)
    }

    func testCoordinatesAreUsableByRenderer() {
        // Arrange
        let coords = TestRouteFactory.zigzag(count: 200)
        // A trivial bounding-box check that would fail if NaNs/optionals sneak in
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        XCTAssertGreaterThan(lats.max()!, lats.min()!)
        XCTAssertGreaterThan(lons.max()!, lons.min()!)
    }
}
