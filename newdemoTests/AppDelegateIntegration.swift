//
//  newdemoTests.swift
//  newdemoTests
//
//  Created by Andrew Kis on 15.4.24..
//

import XCTest
import PushwooshFramework
@testable import newdemo

final class newdemoTests: XCTestCase {
    
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
    }
    
    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }
    
    func testAppDelegateConformsToUIApplicationDelegate() {
        XCTAssertTrue(appDelegate.conforms(to: UIApplicationDelegate.self))
    }
    
    func testDidFinishLaunchingWithOptions() {
        let didFinishLaunching = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
        XCTAssertTrue(didFinishLaunching)
    }
    
    func testDidRegisterForRemoteNotificationsWithDeviceToken() {
        let deviceToken = Data()
        appDelegate.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func testDidFailToRegisterForRemoteNotificationsWithError() {
        let error = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        appDelegate.application(UIApplication.shared, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func testDidReceiveRemoteNotification() {
        let userInfo: [AnyHashable : Any] = [:]
        let expectation = XCTestExpectation(description: "Completion handler called")
        appDelegate.application(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in
            XCTAssertEqual(result, .noData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPushwooshOnMessageOpened() {
        let pushwoosh = Pushwoosh()
        let message = PWMessage()
        appDelegate.pushwoosh(pushwoosh, onMessageOpened: message)
    }
    
    func testPushwooshOnMessageReceived() {
        let pushwoosh = Pushwoosh()
        let message = PWMessage()
        appDelegate.pushwoosh(pushwoosh, onMessageReceived: message)
    }
    
}
