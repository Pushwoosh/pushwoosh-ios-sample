//
//  StoryReelActivity.swift
//  LiveActivityDemo
//
//  Created by André Kis on 16.07.26.
//
//  One story = one Live Activity card. Starting several makes iOS group them
//  under the app on the Lock Screen (the StoryReel look). Cover images are
//  bundled in the widget asset catalog — LA can't load remote images.
//

import ActivityKit
import WidgetKit
import SwiftUI
import PushwooshLiveActivities

private let reelPink = Color(red: 0.93, green: 0.11, blue: 0.42)

@available(iOS 16.1, *)
struct StoryReelActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StoryReelAttributes.self) { context in
            StoryReelLockScreenView(context: context)
                .activitySystemActionForegroundColor(reelPink)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(context.attributes.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.cta)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(reelPink)
                }
            } compactLeading: {
                Image(systemName: "play.rectangle.fill").foregroundStyle(reelPink)
            } compactTrailing: {
                Image(context.attributes.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            } minimal: {
                Image(systemName: "play.rectangle.fill").foregroundStyle(reelPink)
            }
            .keylineTint(reelPink)
        }
    }
}

@available(iOS 16.1, *)
struct StoryReelLockScreenView: View {
    let context: ActivityViewContext<StoryReelAttributes>

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(context.attributes.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 66, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(context.attributes.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(context.state.summary)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Link(destination: URL(string: "pushwoosh-sample://storyreel/\(context.attributes.image)")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(context.attributes.cta)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(reelPink))
                }
                .padding(.top, 3)
            }
        }
        .padding(14)
    }
}

@available(iOS 16.1, *)
extension StoryReelAttributes {
    fileprivate static var preview: StoryReelAttributes { demoStories[0].attributes }
}

@available(iOS 16.2, *)
#Preview("StoryReel", as: .content, using: StoryReelAttributes.preview) {
    StoryReelActivity()
} contentStates: {
    StoryReelAttributes.demoStories[0].state
}
