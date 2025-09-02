import XCTest
@testable import PrintMyRide

final class PosterBuilderTests: XCTestCase {
    
    func testMetricsBandHeight() {
        let spec = PosterSpec(ratio: .threeFour, canvas: CGSize(width: 1080, height: 1440))
        XCTAssertEqual(round(spec.metricsBandRect.height), round(1440 * 0.15))
    }
    
    func testSafeZoneCalculation() {
        let spec = PosterSpec(ratio: .threeFour, canvas: CGSize(width: 1080, height: 1440))
        let expectedSafeInset = min(1080, 1440) * 0.10 // 108
        XCTAssertEqual(spec.safeInset, expectedSafeInset)
    }
    
    func testContentRectWithinBounds() {
        let spec = PosterSpec(ratio: .threeFour, canvas: CGSize(width: 1080, height: 1440))
        XCTAssertTrue(spec.posterRect.contains(spec.contentRect))
        XCTAssertTrue(spec.contentRect.contains(spec.safeRect))
    }
    
    func testMapRectDoesNotOverlapMetricsBand() {
        let spec = PosterSpec(ratio: .threeFour, canvas: CGSize(width: 1080, height: 1440))
        XCTAssertLessThanOrEqual(spec.mapRect.maxY, spec.metricsBandRect.minY)
    }
}