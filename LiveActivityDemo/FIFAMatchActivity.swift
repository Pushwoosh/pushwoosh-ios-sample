//
//  FIFAMatchActivity.swift
//  LiveActivityDemo
//
//  Created by André Kis on 19.06.26.
//

import ActivityKit
import WidgetKit
import SwiftUI
import PushwooshLiveActivities

private let pitchGreen = Color(red: 0.04, green: 0.30, blue: 0.16)
private let neon = Color(red: 0.18, green: 0.85, blue: 0.55)

@available(iOS 16.1, *)
struct FIFAMatchActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FIFAMatchAttributes.self) { context in
            FIFALockScreenView(context: context)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    teamCorner(flag: context.attributes.homeFlag, abbr: context.attributes.homeAbbr)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    teamCorner(flag: context.attributes.awayFlag, abbr: context.attributes.awayAbbr)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 3) {
                        Text("\(context.state.homeScore) – \(context.state.awayScore)")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        clockPill(context.state)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.statusLine)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            } compactLeading: {
                Text(context.attributes.homeFlag)
                    .font(.system(size: 16))
            } compactTrailing: {
                Text("\(context.state.homeScore)–\(context.state.awayScore)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } minimal: {
                Text("\(context.state.homeScore)–\(context.state.awayScore)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(neon)
            }
            .keylineTint(neon)
        }
    }

    private func teamCorner(flag: String, abbr: String) -> some View {
        VStack(spacing: 3) {
            Text(flag).font(.system(size: 26))
            Text(abbr)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func clockPill(_ state: FIFAMatchAttributes.ContentState) -> some View {
        Text(state.clock)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(state.isLive ? .black : .white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(state.isLive ? neon : Color.white.opacity(0.15)))
    }
}

@available(iOS 16.1, *)
struct FIFALockScreenView: View {
    let context: ActivityViewContext<FIFAMatchAttributes>

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(neon)
                Text(context.attributes.competition.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                if context.state.isLive {
                    HStack(spacing: 4) {
                        Circle().fill(.red).frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                } else {
                    Text(context.attributes.venue)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            HStack(spacing: 8) {
                teamColumn(flag: context.attributes.homeFlag, abbr: context.attributes.homeAbbr)
                Spacer(minLength: 4)
                VStack(spacing: 4) {
                    Text("\(context.state.homeScore)  –  \(context.state.awayScore)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    clockPill
                }
                Spacer(minLength: 4)
                teamColumn(flag: context.attributes.awayFlag, abbr: context.attributes.awayAbbr)
            }

            Text(context.state.statusLine)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Color.black
                LinearGradient(colors: [pitchGreen.opacity(0.9), .black],
                               startPoint: .top, endPoint: .bottom)
                LinearGradient(colors: [neon.opacity(0.10), .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
    }

    private func teamColumn(flag: String, abbr: String) -> some View {
        VStack(spacing: 4) {
            Text(flag).font(.system(size: 34))
            Text(abbr)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 66)
    }

    private var clockPill: some View {
        Text(context.state.clock)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(context.state.isLive ? .black : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Capsule().fill(context.state.isLive ? neon : Color.white.opacity(0.15)))
    }
}

@available(iOS 16.1, *)
extension FIFAMatchAttributes {
    fileprivate static var final: FIFAMatchAttributes {
        FIFAMatchAttributes(
            homeTeam: "Argentina", awayTeam: "France",
            homeAbbr: "ARG", awayAbbr: "FRA",
            homeFlag: "🇦🇷", awayFlag: "🇫🇷",
            competition: "FIFA World Cup · Final",
            venue: "Lusail Stadium",
            pushwoosh: PushwooshLiveActivityAttributeData(activityId: "preview")
        )
    }
}

@available(iOS 16.1, *)
extension FIFAMatchAttributes.ContentState {
    fileprivate static var kickoff: FIFAMatchAttributes.ContentState {
        .init(homeScore: 0, awayScore: 0, clock: "KO 18:00", statusLine: "Kicks off at 18:00 · Lusail", isLive: false)
    }
    fileprivate static var live: FIFAMatchAttributes.ContentState {
        .init(homeScore: 2, awayScore: 1, clock: "67'", statusLine: "⚽️ Messi 67' — Argentina lead", isLive: true)
    }
}

@available(iOS 16.2, *)
#Preview("FIFA", as: .content, using: FIFAMatchAttributes.final) {
    FIFAMatchActivity()
} contentStates: {
    FIFAMatchAttributes.ContentState.kickoff
    FIFAMatchAttributes.ContentState.live
}
