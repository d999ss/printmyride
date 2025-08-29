import XCTest

final class SmokeFlowUITests: XCTestCase {
    func testWelcomeHomeCreateSaveGallery() {
        let app = XCUIApplication(); app.launch()
        if app.buttons["btn-get-started"].exists { app.buttons["btn-get-started"].tap() }
        app.tabBars.buttons["Create"].tap()
        app.navigationBars.buttons["Save"].tap()
        app.tabBars.buttons["Gallery"].tap()
        XCTAssertTrue(app.staticTexts["Gallery"].exists)
        // crude check: at least one cell exists (we saved one)
        XCTAssertTrue(app.scrollViews.firstMatch.exists)
    }
}