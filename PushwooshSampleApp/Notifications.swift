//
//  Notifications.swift
//  PushMart
//
//  Created by André Kis
//

import UIKit
import UserNotifications

class Notifications: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = Notifications()
    
    private override init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self
    }
    
    func showLocalNotification(title: String, body: String, delay: TimeInterval = 5) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                // Create notification
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = UNNotificationSound.default

                // Fire after the requested delay (minimum 1s per UNTimeIntervalNotificationTrigger).
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)

                // Unique id so scheduled reminders don't overwrite each other.
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                // Add request to the user notification center
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        print("Notification sent")
                    }
                }
            } else if let error = error {
                print("Something went wrong with permissions: \(error.localizedDescription)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.badge, .list,  .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        
    }
}
