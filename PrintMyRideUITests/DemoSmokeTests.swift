import XCTest

final class DemoSmokeTests: XCTestCase {
    func test_demoFlow() {
        let app = XCUIApplication()
        app.launchArguments += ["--PMRTestMode","--PMRMockStravaOn","--PMRForceUnsubscribed"]
        app.launch()

        // If onboarding appears, tap Start Demo
        let startDemo = app.buttons["Start Demo"]
        if startDemo.waitForExistence(timeout: 2) { startDemo.tap() }

        // Expect Studio tab (scribble icon)
        app.tabBars.buttons.element(boundBy: 1).tap()

        // Tap first poster card
        let firstCell = app.scrollViews.firstMatch.descendants(matching: .any).matching(NSPredicate(format: "identifier == ''")).firstMatch
        if firstCell.waitForExistence(timeout: 3) { firstCell.tap() }

        // Ensure Export button exists
        XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Export High-Res'")).firstMatch.waitForExistence(timeout: 3))

        // Go back
        app.navigationBars.buttons.firstMatch.tap()
    }
}