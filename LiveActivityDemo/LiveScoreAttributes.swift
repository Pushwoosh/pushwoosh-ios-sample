//
//  LiveScoreAttributes.swift
//  LiveActivityDemo
//
//  Created by André Kis on 19.06.26.
//
//  IMPORTANT: this file must be added to BOTH targets — the widget extension
//  (LiveActivityDemoExtension) AND the main PushwooshSampleApp target.
//

import ActivityKit
import PushwooshLiveActivities

@available(iOS 16.1, *)
struct LiveScoreAttributes: PushwooshLiveActivityAttributes {
    var homeTeam: String
    var awayTeam: String
    var homeAbbr: String
    var awayAbbr: String
    var homeFlag: String
    var awayFlag: String
    var competition: String
    var venue: String

    var pushwoosh: PushwooshLiveActivityAttributeData

    struct ContentState: PushwooshLiveActivityContentState {
        var homeScore: Int
        var awayScore: Int
        var clock: String
        var statusLine: String
        var isLive: Bool

        var pushwoosh: PushwooshLiveActivityContentStateData?
    }
}
