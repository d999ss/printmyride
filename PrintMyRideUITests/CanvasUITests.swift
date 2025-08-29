import XCTest

final class CanvasUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testToolbarButtonsExist() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["btn-import"].exists)
        XCTAssertTrue(app.buttons["btn-style"].exists)
        XCTAssertTrue(app.buttons["btn-canvas"].exists)
        XCTAssertTrue(app.buttons["btn-export"].exists)
    }

    func testGridToggleWorks() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["btn-canvas"].tap()
        let toggle = app.switches["Show grid"]
        XCTAssertTrue(toggle.exists)
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1")
    }

    func testShowGridToggleExists() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate into the Canvas sheet
        // Assuming you have a "Canvas" button in the toolbar
        app.buttons["btn-canvas"].tap()

        // Assert the "Show grid" toggle is present
        let toggle = app.switches["Show grid"]
        XCTAssertTrue(toggle.exists, "Show grid toggle should exist in Canvas sheet")

        // Optionally: toggle it on/off and assert state
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1")

        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
    }
}