import XCTest

final class PMRUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--PMRTestMode")
        app.launch()
    }

    func testFirstRunShowsGallery() {
        XCTAssertTrue(app.navigationBars["Your Posters"].waitForExistence(timeout: 5))
    }

    func testSettingsOpens() {
        app.buttons["gear"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Account & Profile"].exists)
        XCTAssertTrue(app.staticTexts["Subscription"].exists)
    }

    func testPaywallCallablePathExists() {
        // Verify we can navigate to paywall via upgrade affordance in Settings later.
        // Placeholder: assert Manage Subscription button exists
        app.buttons["gear"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Manage"].waitForExistence(timeout: 2))
    }
}