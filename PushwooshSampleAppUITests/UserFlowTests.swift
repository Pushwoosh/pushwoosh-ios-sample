//
//  UserFlowTests.swift
//  PushwooshSampleAppUITests
//

import XCTest

final class UserFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]

        // Force portrait orientation
        XCUIDevice.shared.orientation = .portrait

        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSetAndGetUserId() throws {
        // Step 1: Wait for app to load and verify USER screen is shown
        let header = app.staticTexts["USER"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "USER header should exist")

        // Step 3: Enter User ID
        let testUserId = "test_user_\(Int(Date().timeIntervalSince1970))"
        let userIdTextField = app.textFields["userIdTextField"]
        XCTAssertTrue(userIdTextField.waitForExistence(timeout: 5), "User ID text field should exist")

        userIdTextField.tap()
        sleep(1)
        userIdTextField.typeText(testUserId)

        // Dismiss keyboard by tapping return/done button
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else if app.keyboards.buttons["Return"].exists {
            app.keyboards.buttons["Return"].tap()
        } else if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        } else if app.buttons["Return"].exists {
            app.buttons["Return"].tap()
        }
        sleep(1)

        // Step 4: Tap Set User ID button
        let setUserIdButton = app.buttons["Set User ID"]
        XCTAssertTrue(setUserIdButton.exists, "Set User ID button should exist")
        setUserIdButton.tap()

        // Step 5: Wait a bit for the operation to complete
        sleep(1)

        // Step 6: Scroll down and tap Get Current User ID button
        let getCurrentUserIdButton = app.buttons["Get Current User ID"]
        XCTAssertTrue(getCurrentUserIdButton.exists, "Get Current User ID button should exist")

        // Scroll until the button is visible
        for _ in 0..<5 {
            if getCurrentUserIdButton.isHittable {
                break
            }
            // Swipe up from bottom area to scroll content down
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            start.press(forDuration: 0.1, thenDragTo: end)
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Force tap on button using coordinates if still not hittable
        if !getCurrentUserIdButton.isHittable {
            getCurrentUserIdButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else {
            getCurrentUserIdButton.tap()
        }

        // Step 7: Wait for alert to appear and verify
        sleep(2)

        // Try to find alert with different approaches
        var alert = app.alerts["USER ID"]
        if !alert.exists {
            // Try finding any alert
            alert = app.alerts.element(boundBy: 0)
        }

        XCTAssertTrue(alert.waitForExistence(timeout: 5), "USER ID alert should appear. Alert exists: \(alert.exists), alerts count: \(app.alerts.count)")

        let alertMessage = alert.staticTexts.element(boundBy: 1).label
        XCTAssertEqual(alertMessage, testUserId, "Alert should show the User ID we just set")

        // Step 8: Dismiss alert
        alert.buttons["OK"].tap()

        // Step 9: Wait for user to review logs or continue
        print("✅ Test completed successfully!")
        print("📋 You can now:")
        print("   - Expand the log panel at the bottom to review SDK calls")
        print("   - Press Cmd+. to stop and review")
        print("   - Or wait 60 seconds for auto-continue")

        // Wait 60 seconds - user can interrupt with Cmd+. to review logs
        sleep(60)
    }
}
