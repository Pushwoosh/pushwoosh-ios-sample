//
//  RadioBroadcastAttributes.swift
//  LiveActivityDemo
//
//  Created by André Kis on 03.07.26.
//
//  IMPORTANT: this file must be added to BOTH targets — the widget extension
//  (LiveActivityDemoExtension) AND the main PushwooshSampleApp target.
//

import ActivityKit
import PushwooshLiveActivities

@available(iOS 16.1, *)
struct RadioBroadcastAttributes: PushwooshLiveActivityAttributes {
    var station: String
    var show: String
    var host: String
    var frequency: String
    var genre: String

    var pushwoosh: PushwooshLiveActivityAttributeData

    struct ContentState: PushwooshLiveActivityContentState {
        var nowPlaying: String
        var statusLine: String
        var isOnAir: Bool

        var pushwoosh: PushwooshLiveActivityContentStateData?
    }
}
