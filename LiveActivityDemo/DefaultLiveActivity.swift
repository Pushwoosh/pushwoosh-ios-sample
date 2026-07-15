//
//  DefaultLiveActivity.swift
//  LiveActivityDemo
//
//  Created by André Kis on 09.07.26.
//

import ActivityKit
import WidgetKit
import SwiftUI
import PushwooshLiveActivities

private let defaultBrand = Color(red: 1.0, green: 0.43, blue: 0.29)
private let defaultInk = Color(red: 0.05, green: 0.05, blue: 0.07)

private func value(_ dict: [String: AnyCodable], _ key: String, fallback: String) -> String {
    guard let raw = dict[key]?.value else { return fallback }
    let text = String(describing: raw)
    return text.isEmpty ? fallback : text
}

@available(iOS 16.1, *)
struct DefaultLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DefaultLiveActivityAttributes.self) { context in
            DefaultLockScreenView(context: context)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(defaultBrand)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(value(context.state.data, "eta", fallback: ""))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(value(context.attributes.data, "title", fallback: "PushMart order"))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                        Text(value(context.state.data, "status", fallback: "Updating…"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            } compactLeading: {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(defaultBrand)
            } compactTrailing: {
                Text(value(context.state.data, "status", fallback: "…"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(defaultBrand)
            }
            .keylineTint(defaultBrand)
        }
    }
}

@available(iOS 16.1, *)
private struct DefaultLockScreenView: View {
    let context: ActivityViewContext<DefaultLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(defaultBrand.opacity(0.18))
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(defaultBrand)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(value(context.attributes.data, "title", fallback: "PushMart order").uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(defaultBrand.opacity(0.9))
                    .lineLimit(1)

                Text(value(context.state.data, "status", fallback: "Updating…"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 8)

            VStack(spacing: 1) {
                Text(value(context.state.data, "eta", fallback: "—"))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(defaultBrand)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("ETA")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                defaultInk
                LinearGradient(colors: [defaultBrand.opacity(0.16), .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
    }
}
