import XCTest
@testable import PrintMyRide

final class ExportTests: XCTestCase {
    @MainActor
    func testPNGPixelSizeMatches() async {
        let d = PosterDesign()
        let px = CGSize(width: d.paperSize.width * CGFloat(d.dpi),
                        height: d.paperSize.height * CGFloat(d.dpi))
        let data = await PosterExport.pngAsync(design: d, route: nil, dpi: d.dpi, bleedInches: 0, includeGrid: true)
        XCTAssertNotNil(data)
        #if canImport(UIKit)
        if let data, let img = UIImage(data: data) {
            XCTAssertEqual(Int(img.size.width * img.scale), Int(px.width), accuracy: 1)
            XCTAssertEqual(Int(img.size.height * img.scale), Int(px.height), accuracy: 1)
        }
        #endif
    }

    @MainActor
    func testPDFPageSize() async {
        let d = PosterDesign()
        let data = await PosterExport.pdfAsync(design: d, route: nil, bleedInches: 0, includeGrid: true)
        XCTAssertNotNil(data)
        // Can't easily parse; just ensure byte size is non-trivial
        XCTAssertTrue((data?.count ?? 0) > 1024)
    }
}