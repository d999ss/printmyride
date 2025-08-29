import XCTest
@testable import PrintMyRide

final class SimplifyTests: XCTestCase {
    func testRDPReducesButKeepsEnds() {
        let pts = (0..<100).map { i in CGPoint(x: CGFloat(i), y: sin(CGFloat(i)/5)*10) }
        let simp = Simplify.rdp(pts, epsilon: 0.5)
        XCTAssertTrue(simp.count < pts.count)
        XCTAssertEqual(simp.first!, pts.first!)
        XCTAssertEqual(simp.last!, pts.last!)
    }

    func testBudgetKeepsEnds() {
        let pts = (0..<100).map { CGPoint(x: CGFloat($0), y: 0) }
        let out = Simplify.budget(pts, maxPoints: 20)
        XCTAssertEqual(out.count, 20)
        XCTAssertEqual(out.first!, pts.first!)
        XCTAssertEqual(out.last!, pts.last!)
    }
}