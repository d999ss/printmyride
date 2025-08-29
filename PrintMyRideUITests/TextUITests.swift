import XCTest

final class TextUITests: XCTestCase {
    func testTextOverlayPersists() {
        let app = XCUIApplication()
        app.launch()
        
        if app.buttons["btn-get-started"].exists {
            app.buttons["btn-get-started"].tap()
        }
        
        app.tabBars.buttons["Create"].tap()
        app.buttons["btn-sample"].tap() // Load sample route first
        app.buttons["Text"].tap()
        
        let titleField = app.textFields["Title"]
        if titleField.exists {
            titleField.tap()
            titleField.clearAndEnterText("Park City Loop")
        }
        
        app.buttons["Apply"].firstMatch.tapIfExists()
        app.navigationBars.buttons["Save"].tap()
        app.tabBars.buttons["Gallery"].tap()
        
        XCTAssertTrue(app.staticTexts["Park City Loop"].exists)
    }
}

private extension XCUIElement {
    func tapIfExists() {
        if exists {
            tap()
        }
    }
    
    func clearAndEnterText(_ text: String) {
        guard exists else { return }
        tap()
        press(forDuration: 1.2)
        XCUIApplication().menuItems["Select All"].tap()
        typeText(text)
    }
}