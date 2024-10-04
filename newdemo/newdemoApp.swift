//
//  newdemoApp.swift
//  newdemo
//
//  Created by Andrew Kis on 12.4.24..
//

import SwiftUI
import PushwooshFramework

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, PWMessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        Pushwoosh.sharedInstance().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Pushwoosh.sharedInstance().handlePushRegistration(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        Pushwoosh.sharedInstance().handlePushRegistrationFailure(error)
        print("\(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Pushwoosh.sharedInstance().handlePushReceived(userInfo)
        
        completionHandler(.noData)
    }

    func pushwoosh(_ pushwoosh: Pushwoosh, onMessageOpened message: PWMessage) {
        print("Push Opened: \(message.payload ?? ["" : ""])")
    }

    func pushwoosh(_ pushwoosh: Pushwoosh, onMessageReceived message: PWMessage) {
        print("Push Received: \(message.payload ?? ["" : ""])")
    }
}

@main
struct newdemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
