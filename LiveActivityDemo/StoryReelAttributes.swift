//
//  StoryReelAttributes.swift
//  LiveActivityDemo
//
//  Created by André Kis on 16.07.26.
//
//  IMPORTANT: this file must be added to BOTH targets — the widget extension
//  (LiveActivityDemoExtension) AND the main PushwooshSampleApp target.
//
//  Each story is its OWN Live Activity (one card). Starting several of them
//  makes iOS group the cards on the Lock Screen under the app, exactly like the
//  StoryReel screenshot. Cover images are bundled in the widget's asset catalog
//  (Live Activities cannot load remote images at render time).
//

import ActivityKit
import PushwooshLiveActivities

@available(iOS 16.1, *)
struct StoryReelAttributes: PushwooshLiveActivityAttributes {
    var title: String
    var cta: String
    var image: String

    var pushwoosh: PushwooshLiveActivityAttributeData

    struct ContentState: PushwooshLiveActivityContentState {
        var summary: String

        var pushwoosh: PushwooshLiveActivityContentStateData?
    }
}

@available(iOS 16.1, *)
extension StoryReelAttributes {
    // Two demo stories → two separate Live Activities (iOS groups the cards under the app).
    static var demoStories: [(attributes: StoryReelAttributes, state: ContentState)] {
        [
            (StoryReelAttributes(title: "Rejected at the Altar, Claimed by the Cursed Alpha",
                                 cta: "Continue Watch",
                                 image: "storyreel_1",
                                 pushwoosh: PushwooshLiveActivityAttributeData(activityId: "storyreel-1")),
             ContentState(summary: "In the werewolf realm of Silvercrest, Seraphina, an Omega with the legendary silver bloodline…",
                          pushwoosh: nil)),
            (StoryReelAttributes(title: "Don't Piss off Your Medical Genius Ex-wife",
                                 cta: "Continue",
                                 image: "storyreel_2",
                                 pushwoosh: PushwooshLiveActivityAttributeData(activityId: "storyreel-2")),
             ContentState(summary: "Omega Lyra gives up her post as Chief Doctor for love to marry a Beta who never deserved her…",
                          pushwoosh: nil))
        ]
    }
}
