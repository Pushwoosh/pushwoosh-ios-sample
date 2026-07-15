//
//  LiveActivityDemoLiveActivity.swift
//  LiveActivityDemo
//
//  Created by André Kis on 21.05.26.
//

import ActivityKit
import WidgetKit
import SwiftUI
import PushwooshLiveActivities

private enum EatsTheme {
    static let amberLight = Color(eats: 0xFF8A3D)
    static let amber = Color(eats: 0xFF6E4A)
    static let amberDeep = Color(eats: 0xFF5A5F)
    static let charcoal = Color(eats: 0x0B0B10)

    static let numberGradient = LinearGradient(
        colors: [amberLight, amber],
        startPoint: .top,
        endPoint: .bottom
    )
    static let nodeGradient = LinearGradient(
        colors: [amberLight, amberDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private enum DeliveryStage: Int, CaseIterable {
    case placed = 0
    case packed = 1
    case shipped = 2
    case delivered = 3

    var icon: String {
        switch self {
        case .placed: return "checkmark.circle.fill"
        case .packed: return "shippingbox.fill"
        case .shipped: return "truck.box.fill"
        case .delivered: return "house.fill"
        }
    }

    static func from(status: String) -> DeliveryStage {
        let text = status.lowercased()
        let match: ([String]) -> Bool = { keys in keys.contains { text.contains($0) } }
        if match(["delivered", "arriv", "door", "here", "complete"]) { return .delivered }
        if match(["way", "courier", "out for", "ship", "transit", "route", "driv", "dispatch"]) { return .shipped }
        if match(["pack", "prepar", "ready", "warehouse", "picking"]) { return .packed }
        if match(["placed", "confirm", "received", "order"]) { return .placed }
        return .packed
    }
}

struct LiveActivityDemoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityDemoAttributes.self) { context in
            LockScreenDeliveryView(context: context)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EmojiMedallion(emoji: context.state.emoji, size: 44)
                        .padding(.leading, 2)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    EtaBlock(estimatedTime: context.state.estimatedTime, numberSize: 26)
                        .padding(.trailing, 2)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.status)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    RouteTracker(stage: DeliveryStage.from(status: context.state.status), compact: true)
                        .padding(.top, 6)
                        .padding(.horizontal, 2)
                }

            } compactLeading: {
                Text(context.state.emoji)
                    .font(.system(size: 18))

            } compactTrailing: {
                Text(shortEta(context.state.estimatedTime))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(EatsTheme.amber)

            } minimal: {
                Text(context.state.emoji)
                    .font(.system(size: 16))
            }
            .keylineTint(EatsTheme.amber)
        }
    }
}

private func etaMinutes(_ estimatedTime: String) -> String? {
    let digits = estimatedTime.prefix { $0.isNumber || $0.isWhitespace }
        .filter { $0.isNumber }
    return digits.isEmpty ? nil : String(digits)
}

private func shortEta(_ estimatedTime: String) -> String {
    if let minutes = etaMinutes(estimatedTime) { return "\(minutes)m" }
    return estimatedTime
}

private struct LockScreenDeliveryView: View {
    let context: ActivityViewContext<LiveActivityDemoAttributes>

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                EmojiMedallion(emoji: context.state.emoji, size: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text("PUSHMART ORDER · #\(context.attributes.pushwoosh.activityId.uppercased())")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(EatsTheme.amber.opacity(0.9))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(context.state.status)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 8)

                EtaBlock(estimatedTime: context.state.estimatedTime, numberSize: 30)
            }

            RouteTracker(stage: DeliveryStage.from(status: context.state.status), compact: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                EatsTheme.charcoal
                LinearGradient(
                    colors: [EatsTheme.amber.opacity(0.16), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                RadialGradient(
                    colors: [EatsTheme.amber.opacity(0.22), .clear],
                    center: .topLeading,
                    startRadius: 4,
                    endRadius: 150
                )
            }
        )
    }
}

private struct EmojiMedallion: View {
    let emoji: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [EatsTheme.amber.opacity(0.35), EatsTheme.amber.opacity(0.06)],
                        center: .center,
                        startRadius: 2,
                        endRadius: size * 0.65
                    )
                )

            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [EatsTheme.amberLight.opacity(0.8), EatsTheme.amberDeep.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            Text(emoji)
                .font(.system(size: size * 0.52))
        }
        .frame(width: size, height: size)
    }
}

private struct EtaBlock: View {
    let estimatedTime: String
    let numberSize: CGFloat

    var body: some View {
        VStack(spacing: 1) {
            if let minutes = etaMinutes(estimatedTime) {
                Text(minutes)
                    .font(.system(size: numberSize, weight: .black, design: .rounded))
                    .foregroundStyle(EatsTheme.numberGradient)
                Text("ETA")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.45))
            } else {
                Text(estimatedTime)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(EatsTheme.numberGradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

private struct RouteTracker: View {
    let stage: DeliveryStage
    let compact: Bool

    private var nodeSize: CGFloat { compact ? 20 : 24 }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(DeliveryStage.allCases, id: \.rawValue) { step in
                node(for: step)
                if step != .delivered {
                    connector(reached: step.rawValue < stage.rawValue)
                }
            }
        }
    }

    private func node(for step: DeliveryStage) -> some View {
        let reached = step.rawValue <= stage.rawValue
        let isCurrent = step == stage

        return ZStack {
            Circle()
                .fill(reached ? AnyShapeStyle(EatsTheme.nodeGradient) : AnyShapeStyle(Color.white.opacity(0.1)))

            if isCurrent {
                Circle()
                    .strokeBorder(EatsTheme.amberLight.opacity(0.6), lineWidth: 1.5)
                    .padding(-3)
            }

            Image(systemName: step.icon)
                .font(.system(size: nodeSize * 0.42, weight: .bold))
                .foregroundStyle(reached ? EatsTheme.charcoal : .white.opacity(0.4))
        }
        .frame(width: nodeSize, height: nodeSize)
        .scaleEffect(isCurrent ? 1.12 : 1.0)
        .shadow(color: isCurrent ? EatsTheme.amber.opacity(0.55) : .clear, radius: 6, x: 0, y: 2)
    }

    private func connector(reached: Bool) -> some View {
        Capsule()
            .fill(reached ? AnyShapeStyle(EatsTheme.nodeGradient) : AnyShapeStyle(Color.white.opacity(0.1)))
            .frame(height: 3)
            .frame(maxWidth: .infinity)
    }
}

private extension Color {
    init(eats hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension LiveActivityDemoAttributes {
    fileprivate static var preview: LiveActivityDemoAttributes {
        LiveActivityDemoAttributes(pushwoosh: PushwooshLiveActivityAttributeData(activityId: "order_42"))
    }
}

extension LiveActivityDemoAttributes.ContentState {
    fileprivate static var placed: LiveActivityDemoAttributes.ContentState {
        LiveActivityDemoAttributes.ContentState(status: "Order confirmed", estimatedTime: "2 days", emoji: "🧾", pushwoosh: nil)
    }

    fileprivate static var preparing: LiveActivityDemoAttributes.ContentState {
        LiveActivityDemoAttributes.ContentState(status: "Packed & ready", estimatedTime: "1 day", emoji: "📦", pushwoosh: nil)
    }

    fileprivate static var onTheWay: LiveActivityDemoAttributes.ContentState {
        LiveActivityDemoAttributes.ContentState(status: "Out for delivery", estimatedTime: "20 min", emoji: "🚚", pushwoosh: nil)
    }

    fileprivate static var atTheDoor: LiveActivityDemoAttributes.ContentState {
        LiveActivityDemoAttributes.ContentState(status: "Delivered", estimatedTime: "Now", emoji: "🎉", pushwoosh: nil)
    }
}

#Preview("Notification", as: .content, using: LiveActivityDemoAttributes.preview) {
   LiveActivityDemoLiveActivity()
} contentStates: {
    LiveActivityDemoAttributes.ContentState.placed
    LiveActivityDemoAttributes.ContentState.preparing
    LiveActivityDemoAttributes.ContentState.onTheWay
    LiveActivityDemoAttributes.ContentState.atTheDoor
}
