//
//  RadioBroadcastActivity.swift
//  LiveActivityDemo
//
//  Created by André Kis on 03.07.26.
//

import ActivityKit
import WidgetKit
import SwiftUI
import PushwooshLiveActivities

private let studioBlack = Color(red: 0.07, green: 0.06, blue: 0.10)
private let amber = Color(red: 1.00, green: 0.72, blue: 0.30)

@available(iOS 16.1, *)
struct RadioBroadcastActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RadioBroadcastAttributes.self) { context in
            RadioLockScreenView(context: context)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(spacing: 3) {
                        Image(systemName: "radio.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(amber)
                        Text(context.attributes.frequency)
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 3) {
                        Image(systemName: "person.wave.2.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(context.attributes.host)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 3) {
                        Text(context.attributes.show)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        onAirPill(context.state)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.statusLine)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "radio.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(amber)
            } compactTrailing: {
                if context.state.isOnAir {
                    HStack(spacing: 3) {
                        Circle().fill(.red).frame(width: 6, height: 6)
                        Text("AIR")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                } else {
                    Text(context.attributes.frequency)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
            } minimal: {
                Image(systemName: "radio.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(context.state.isOnAir ? .red : amber)
            }
            .keylineTint(amber)
        }
    }

    private func onAirPill(_ state: RadioBroadcastAttributes.ContentState) -> some View {
        HStack(spacing: 4) {
            if state.isOnAir {
                Circle().fill(.red).frame(width: 6, height: 6)
            }
            Text(state.isOnAir ? "ON AIR" : state.nowPlaying)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(state.isOnAir ? .white : .black)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Capsule().fill(state.isOnAir ? Color.red.opacity(0.85) : amber))
    }
}

@available(iOS 16.1, *)
struct RadioLockScreenView: View {
    let context: ActivityViewContext<RadioBroadcastAttributes>

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 10))
                    .foregroundStyle(amber)
                Text(context.attributes.station.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                if context.state.isOnAir {
                    HStack(spacing: 4) {
                        Circle().fill(.red).frame(width: 6, height: 6)
                        Text("ON AIR")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                } else {
                    Text(context.attributes.genre)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(amber.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "radio.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(amber)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.attributes.show)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("with \(context.attributes.host)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Text(context.attributes.frequency)
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundStyle(amber)
            }

            HStack(spacing: 6) {
                Image(systemName: context.state.isOnAir ? "music.note" : "clock")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                Text(context.state.statusLine)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Color.black
                LinearGradient(colors: [studioBlack, .black],
                               startPoint: .top, endPoint: .bottom)
                LinearGradient(colors: [amber.opacity(0.12), .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
    }
}

@available(iOS 16.1, *)
extension RadioBroadcastAttributes {
    fileprivate static var morningDrive: RadioBroadcastAttributes {
        RadioBroadcastAttributes(
            station: "PW Radio One",
            show: "Morning Drive",
            host: "Alex Carter",
            frequency: "98.5 FM",
            genre: "Talk · News",
            pushwoosh: PushwooshLiveActivityAttributeData(activityId: "preview")
        )
    }
}

@available(iOS 16.1, *)
extension RadioBroadcastAttributes.ContentState {
    fileprivate static var upcoming: RadioBroadcastAttributes.ContentState {
        .init(nowPlaying: "Starts 08:00", statusLine: "Goes on air at 08:00", isOnAir: false)
    }
    fileprivate static var onAir: RadioBroadcastAttributes.ContentState {
        .init(nowPlaying: "Daft Punk — Voyager", statusLine: "Now playing: Daft Punk — Voyager", isOnAir: true)
    }
}

@available(iOS 16.2, *)
#Preview("Radio", as: .content, using: RadioBroadcastAttributes.morningDrive) {
    RadioBroadcastActivity()
} contentStates: {
    RadioBroadcastAttributes.ContentState.upcoming
    RadioBroadcastAttributes.ContentState.onAir
}
