//
//  LiveActivityDemoAttributes.swift
//  LiveActivityDemo
//
//  Created by André Kis on 21.05.26.
//
//  IMPORTANT: this file must be added to BOTH targets — the widget extension
//  AND the main PushwooshSampleApp target (Target Membership in Xcode).
//

import ActivityKit
import PushwooshLiveActivities

@available(iOS 16.1, *)
struct LiveActivityDemoAttributes: PushwooshLiveActivityAttributes {
    public struct ContentState: PushwooshLiveActivityContentState {
        var status: String
        var estimatedTime: String
        var emoji: String
        var pushwoosh: PushwooshLiveActivityContentStateData?
    }

    var pushwoosh: PushwooshLiveActivityAttributeData
}
