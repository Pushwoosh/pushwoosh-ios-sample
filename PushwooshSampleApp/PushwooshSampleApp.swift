//
//  newdemoApp.swift
//  newdemo
//
//  Created by Andrew Kis on 12.4.24..
//

import SwiftUI
import PushwooshFramework
import PushwooshLiveActivities

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, PWMessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Skip Pushwoosh initialization during UI tests
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
            print("🧪 UI Testing mode - skipping Pushwoosh initialization")
            return true
        }

        Pushwoosh.configure.delegate = self

        Pushwoosh.LiveActivities.defaultSetup()

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Pushwoosh.configure.handlePushRegistration(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        Pushwoosh.configure.handlePushRegistrationFailure(error as NSError)
        print("\(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Pushwoosh.configure.handlePushReceived(userInfo)

        completionHandler(.noData)
    }

    func pushwoosh(_ pushwoosh: Pushwoosh, onMessageOpened message: PWMessage) {
        print("Push Opened: \(message.payload ?? ["" : ""])")
    }

    func pushwoosh(_ pushwoosh: Pushwoosh, onMessageReceived message: PWMessage) {
        // print("Push Received: \(message.payload ?? ["" : ""])")
    }
}

@main
struct PushwooshSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
