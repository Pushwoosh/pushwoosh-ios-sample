import XCTest
import UserNotifications
@testable import newdemo

class NotificationsTests: XCTestCase {
    var notifications: Notifications!

    override func setUp() {
        super.setUp()
        notifications = Notifications.shared
    }

    override func tearDown() {
        notifications = nil
        super.tearDown()
    }

    func testShowLocalNotification() {
        let expectation = XCTestExpectation(description: "Local notification sent")

        notifications.showLocalNotification(title: "Test Title", body: "Test Body")

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
}
