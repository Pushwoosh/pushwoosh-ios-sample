//
//  NotificationService.swift
//  NotificationService
//
//  Created by Andrew Kis on 12.4.24..
//

import UserNotifications
import PushwooshFramework
import PushwooshNotificationUI

class NotificationService: PushwooshNotificationServiceExtension {

    private let storiesAppGroup = "group.com.example.pushstories"

    override func pushwooshAppGroupsName() -> String? {
        "group.com.example.delivery"
    }

    override func pushwooshPrepare(for request: UNNotificationRequest, completion: @escaping () -> Void) {
        guard request.content.userInfo["pw_stories"] != nil else {
            completion()
            return
        }

        PushwooshStoriesMediaPrefetcher.prefetch(userInfo: request.content.userInfo,
                                                 appGroupIdentifier: storiesAppGroup) {
            completion()
        }
    }

}
