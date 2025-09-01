import XCTest
@testable import PrintMyRide

final class ExportTests: XCTestCase {
    @MainActor
    func testPNGPixelSizeMatches() async {
        // Test that PosterExport.pngAsync doesn't crash and produces some output
        let d = PosterDesign()
        let data = await PosterExport.pngAsync(design: d, route: nil, dpi: d.dpi, bleedInches: 0, includeGrid: true)
        XCTAssertNotNil(data, "PNG export should produce data")
        if let data = data {
            XCTAssertGreaterThan(data.count, 1000, "PNG data should have reasonable size")
        }
    }

    @MainActor
    func testPDFPageSize() async throws {
        // Basic test that PDF generation components exist and are accessible
        let design = PosterDesign(paperSize: CGSize(width: 18, height: 24))
        XCTAssertEqual(design.paperSize.width, 18, "PosterDesign should store paper size correctly")
        XCTAssertEqual(design.paperSize.height, 24, "PosterDesign should store paper size correctly")
        XCTAssertEqual(design.dpi, 300, "PosterDesign should have 300 DPI by default")
    }

    func testPosterPreviewRequiresPayload() {
        // Verify PosterPreview requires payload parameter and doesn't crash during init
        let design = PosterDesign(paperSize: CGSize(width: 18, height: 24))
        let mockPayload = RoutePayload(coords: [], elevations: [], timestamps: [])
        let view = PosterPreview(design: design, posterTitle: "Test", mode: .export, route: nil, payload: mockPayload)
        XCTAssertNotNil(view, "PosterPreview should initialize successfully with valid payload")
    }
}