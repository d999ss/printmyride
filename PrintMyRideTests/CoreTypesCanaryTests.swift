import XCTest
@testable import PrintMyRide

final class CoreTypesCanaryTests: XCTestCase {

    func testPosterDesignExistsAndDefaults() {
        let design = PosterDesign()
        // sanity check core defaults
        XCTAssertEqual(design.dpi, 300)
        XCTAssertEqual(design.showGrid, false)
        XCTAssertGreaterThan(design.paperSize.width, 0)
        XCTAssertGreaterThan(design.paperSize.height, 0)
    }

    func testGridOverlayIsRenderable() {
        // Just instantiate it — if the type is missing or broken, this won't compile
        let overlay = GridOverlay()
        XCTAssertNotNil(overlay)
    }
}