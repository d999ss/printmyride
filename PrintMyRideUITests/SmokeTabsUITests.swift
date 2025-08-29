import XCTest

final class SmokeTabsUITests: XCTestCase {
    func testTabsExist() {
        let app = XCUIApplication(); app.launch()
        if app.buttons["btn-get-started"].exists { app.buttons["btn-get-started"].tap() }
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Create"].exists)
        XCTAssertTrue(app.tabBars.buttons["Gallery"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
}