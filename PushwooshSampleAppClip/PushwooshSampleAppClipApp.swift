//
//  PushwooshSampleAppClipApp.swift
//  PushwooshSampleAppClip
//
//  Created by André Kis on 19.03.26.
//

import SwiftUI
import PushwooshFramework

class AppClipDelegate: NSObject, UIApplicationDelegate, PWMessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Pushwoosh.configure.delegate = self
        Pushwoosh.sharedInstance().showPushnotificationAlert = false
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Pushwoosh.configure.handlePushRegistration(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Pushwoosh.configure.handlePushRegistrationFailure(error as NSError)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Pushwoosh.configure.handlePushReceived(userInfo)
        completionHandler(.noData)
    }

    func pushwoosh(_ pushwoosh: Pushwoosh, onMessageOpened message: PWMessage) {
        NotificationCenter.default.post(name: .pushReceived, object: nil, userInfo: [
            "title": message.title ?? "New notification",
            "body": message.payload?["body"] as? String ?? ""
        ])
    }

    func pushwoosh(_ pushwoosh: Pushwoosh, onMessageReceived message: PWMessage) {
        NotificationCenter.default.post(name: .pushReceived, object: nil, userInfo: [
            "title": message.title ?? "New notification",
            "body": message.payload?["body"] as? String ?? ""
        ])
    }
}

extension Notification.Name {
    static let pushReceived = Notification.Name("pushReceived")
}

@main
struct PushwooshSampleAppClipApp: App {
    @UIApplicationDelegateAdaptor(AppClipDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RestaurantView()
        }
    }
}
