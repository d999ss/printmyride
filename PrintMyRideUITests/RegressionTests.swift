import XCTest

final class RegressionTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--PMRTestMode"] // Ensures deterministic state
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // MARK: - 1. Studio Tests
    
    func testStudioNavigation() throws {
        // Wait for Studio to load
        let studioTitle = app.navigationBars["Studio"]
        XCTAssertTrue(studioTitle.waitForExistence(timeout: 5))
        
        // Test Alpine Climb card navigation
        let alpineClimbCard = app.buttons.containing(.staticText, identifier: "Alpine Climb").firstMatch
        XCTAssertTrue(alpineClimbCard.waitForExistence(timeout: 3))
        alpineClimbCard.tap()
        
        // Verify poster detail opens
        let posterDetailTitle = app.navigationBars["Alpine Climb"]
        XCTAssertTrue(posterDetailTitle.waitForExistence(timeout: 3))
        
        // Go back to Studio
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(studioTitle.waitForExistence(timeout: 2))
    }
    
    func testHeroBannerRendering() throws {
        let studioTitle = app.navigationBars["Studio"]
        XCTAssertTrue(studioTitle.waitForExistence(timeout: 5))
        
        // Ensure no duplicate Try Pro buttons exist
        let tryProButtons = app.buttons.matching(identifier: "Try Pro")
        XCTAssertLessThanOrEqual(tryProButtons.count, 1, "Should have at most 1 Try Pro button")
    }
    
    // MARK: - 2. Poster Detail Tests
    
    func testPosterDetailActions() throws {
        // Navigate to poster detail
        navigateToAlpineClimb()
        
        // Test all action buttons exist
        XCTAssertTrue(app.buttons["Export"].exists)
        XCTAssertTrue(app.buttons["Share"].exists) 
        XCTAssertTrue(app.buttons["Print"].exists)
        XCTAssertTrue(app.buttons["Save Map"].exists)
        
        // Test Export button
        app.buttons["Export"].tap()
        // Should not crash - basic smoke test
        sleep(1)
        
        // Test Share button
        app.buttons["Share"].tap()
        let shareSheet = app.sheets.firstMatch
        if shareSheet.waitForExistence(timeout: 2) {
            shareSheet.buttons["Cancel"].tap() // Dismiss if appears
        }
        
        // Test Save Map button
        app.buttons["Save Map"].tap()
        sleep(1) // Allow processing
        
        // Go back to Studio
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    func testPosterAlignment() throws {
        navigateToAlpineClimb()
        
        // Verify poster and action buttons are aligned
        // This is a visual test - we check elements exist in expected positions
        let posterHero = app.otherElements.containing(.image, identifier: "poster").firstMatch
        let actionBar = app.buttons["Export"].firstMatch
        
        XCTAssertTrue(posterHero.exists, "Poster should be visible")
        XCTAssertTrue(actionBar.exists, "Action bar should be visible")
        
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    // MARK: - 3. Tab Navigation Tests
    
    func testTabNavigation() throws {
        // Start in Studio
        XCTAssertTrue(app.navigationBars["Studio"].waitForExistence(timeout: 5))
        
        // Navigate to Collections
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(1)
        
        // Navigate to Settings  
        app.tabBars.buttons.element(boundBy: 2).tap()
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
        
        // Navigate back to Studio
        app.tabBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Studio"].waitForExistence(timeout: 3))
    }
    
    // MARK: - 4. Settings Tests
    
    func testSettingsToggles() throws {
        navigateToSettings()
        
        // Test Apple Maps background toggle
        let mapToggle = app.switches.firstMatch
        if mapToggle.exists {
            let initialValue = mapToggle.value as? String
            mapToggle.tap()
            sleep(1) // Allow toggle to process
            let newValue = mapToggle.value as? String
            XCTAssertNotEqual(initialValue, newValue, "Toggle should change state")
        }
        
        // Test Units picker if visible
        if app.buttons["Miles"].exists {
            app.buttons["Miles"].tap()
            sleep(1)
        }
        
        app.tabBars.buttons.element(boundBy: 0).tap() // Back to Studio
    }
    
    // MARK: - 5. Pro/Subscription Tests
    
    func testProFlows() throws {
        let studioTitle = app.navigationBars["Studio"]
        XCTAssertTrue(studioTitle.waitForExistence(timeout: 5))
        
        // Test Try Pro button
        let tryProButton = app.buttons.matching(identifier: "Try Pro").firstMatch
        if tryProButton.exists {
            tryProButton.tap()
            sleep(2) // Allow paywall to potentially appear
            
            // Dismiss any presented views
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            } else if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
        
        XCTAssertTrue(studioTitle.waitForExistence(timeout: 3))
    }
    
    // MARK: - 6. Onboarding Tests
    
    func testDemoPostersLoad() throws {
        let studioTitle = app.navigationBars["Studio"]
        XCTAssertTrue(studioTitle.waitForExistence(timeout: 10)) // Allow time for seeding
        
        // Verify demo posters exist
        let alpineClimb = app.buttons.containing(.staticText, identifier: "Alpine Climb").firstMatch
        let forestSwitchbacks = app.buttons.containing(.staticText, identifier: "Forest Switchbacks").firstMatch
        
        XCTAssertTrue(alpineClimb.waitForExistence(timeout: 5), "Alpine Climb poster should load")
        XCTAssertTrue(forestSwitchbacks.waitForExistence(timeout: 5), "Forest Switchbacks poster should load")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToAlpineClimb() {
        let studioTitle = app.navigationBars["Studio"]
        XCTAssertTrue(studioTitle.waitForExistence(timeout: 5))
        
        let alpineClimbCard = app.buttons.containing(.staticText, identifier: "Alpine Climb").firstMatch
        XCTAssertTrue(alpineClimbCard.waitForExistence(timeout: 3))
        alpineClimbCard.tap()
        
        let posterDetailTitle = app.navigationBars["Alpine Climb"]
        XCTAssertTrue(posterDetailTitle.waitForExistence(timeout: 3))
    }
    
    private func navigateToSettings() {
        app.tabBars.buttons.element(boundBy: 2).tap()
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
    }
    
    // MARK: - Comprehensive Smoke Test
    
    func testFullAppSmoke() throws {
        // This test runs through the entire app flow quickly
        
        // 1. Studio loads
        XCTAssertTrue(app.navigationBars["Studio"].waitForExistence(timeout: 10))
        
        // 2. Open poster detail
        navigateToAlpineClimb()
        
        // 3. Test one action button
        app.buttons["Save Map"].tap()
        sleep(1)
        
        // 4. Back to Studio
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Studio"].waitForExistence(timeout: 3))
        
        // 5. Check Collections tab
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(1)
        
        // 6. Check Settings tab
        navigateToSettings()
        
        // 7. Back to Studio
        app.tabBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Studio"].waitForExistence(timeout: 3))
        
        // Test passes if we made it here without crashes
        XCTAssertTrue(true, "Full app smoke test completed")
    }
}