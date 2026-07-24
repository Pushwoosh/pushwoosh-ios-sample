//
//  ElectionAttributes.swift
//  LiveActivityDemo
//
//  Created by André Kis on 20.07.26.
//
//  IMPORTANT: this file must be added to BOTH targets — the widget extension
//  (LiveActivityDemoExtension) AND the main PushwooshSampleApp target.
//
//  The ContentState mirrors, field for field, the payload a Pushwoosh
//  updateLiveActivity campaign sends for an election tracker: a majority mark
//  (halfwayCount) out of a seat total (targetCount) plus one entry per party.
//  Every property name matches the JSON key 1:1 (Codable keys are the property
//  names), so a remote update decodes straight into this state.
//

import ActivityKit
import PushwooshLiveActivities

@available(iOS 16.1, *)
struct ElectionAttributes: PushwooshLiveActivityAttributes {
    var title: String
    var electionName: String

    var pushwoosh: PushwooshLiveActivityAttributeData

    struct ContentState: PushwooshLiveActivityContentState {
        var halfwayCount: Int
        var targetCount: Int
        var entries: [Party]

        var pushwoosh: PushwooshLiveActivityContentStateData?
    }
}

struct Party: Codable, Hashable {
    var id: String
    var logo: String
    var name: String
    var seatCount: String
    var partyColour: String
    var partyColour1: String
}
