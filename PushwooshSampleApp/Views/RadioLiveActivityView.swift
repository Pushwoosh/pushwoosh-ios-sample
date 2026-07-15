//
//  RadioLiveActivityView.swift
//  PushMart
//
//  "Restock reminders": saved items due back in stock, each scheduled at a
//  different offset via Pushwoosh.LiveActivities.schedule(at:). Reuses the shared
//  RadioBroadcastAttributes type as the LA payload; its fields carry the item's
//  name/brand/variant.
//

import SwiftUI
import ActivityKit
import PushwooshFramework
import PushwooshLiveActivities

// MARK: - Model

struct RestockItem: Identifiable {
    let id: String          // used as the Pushwoosh activityId
    let name: String
    let brand: String
    let variant: String
    let category: String
    let emoji: String
    let minutes: Int        // schedule offset from now
}

// MARK: - Controller

@MainActor
final class RestockController: ObservableObject {
    @Published var scheduledAt: [String: String] = [:]
    @Published var statusLine = "Schedule a restock reminder and watch it reach the Lock Screen"
    @Published var systemActivities: [String] = []

    let items: [RestockItem] = [
        RestockItem(id: "restock_glide", name: "Glide Low", brand: "PushMart Sport",
                    variant: "US 9–12", category: "Sneakers", emoji: "👟", minutes: 1),
        RestockItem(id: "restock_beacon", name: "Beacon Speaker", brand: "PushMart Audio",
                    variant: "All colors", category: "Audio", emoji: "🔊", minutes: 2),
        RestockItem(id: "restock_lumen", name: "Lumen Frames", brand: "PushMart Tech",
                    variant: "Black", category: "Tech", emoji: "🕶", minutes: 3),
        RestockItem(id: "restock_trail", name: "Trail Pack 24L", brand: "PushMart Goods",
                    variant: "Green / Black", category: "Bags", emoji: "🎒", minutes: 4)
    ]

    func configure() {
        if #available(iOS 16.1, *) {
            Pushwoosh.LiveActivities.setup(RadioBroadcastAttributes.self)
        }
        refresh()
    }

    func isScheduled(_ item: RestockItem) -> Bool { scheduledAt[item.id] != nil }

    func schedule(_ item: RestockItem) {
        guard #available(iOS 26.0, *) else {
            statusLine = "Scheduling needs iOS 26"
            return
        }

        let start = Date().addingTimeInterval(Double(item.minutes) * 60)
        let label = start.formatted(date: .omitted, time: .shortened)

        let attrs = RadioBroadcastAttributes(
            station: item.name, show: "Back in stock", host: item.brand,
            frequency: item.variant, genre: item.category,
            pushwoosh: PushwooshLiveActivityAttributeData(activityId: item.id)
        )
        let state = RadioBroadcastAttributes.ContentState(
            nowPlaying: "Restocking at \(label)",
            statusLine: "\(item.name) · \(item.variant)",
            isOnAir: false, pushwoosh: nil
        )

        do {
            try Pushwoosh.LiveActivities.schedule(
                attributes: attrs, contentState: state, at: start,
                alertTitle: "\(item.name) is back",
                alertBody: "\(item.category) · \(item.variant) restocks at \(label)"
            )
            scheduledAt[item.id] = label
            statusLine = "Reminder set for \(item.name) at \(label)  (+\(item.minutes) min)"
        } catch {
            statusLine = "Schedule failed: \(error.localizedDescription)"
        }
        refresh()
    }

    func cancel(_ item: RestockItem) {
        Pushwoosh.LiveActivities.cancel(RadioBroadcastAttributes.self, activityId: item.id)
        scheduledAt[item.id] = nil
        statusLine = "Cancelled reminder for \(item.name)"
        refresh()
    }

    func endAll() {
        if #available(iOS 16.2, *) {
            for activity in Activity<RadioBroadcastAttributes>.activities {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
        }
        scheduledAt.removeAll()
        statusLine = "Cleared all reminders"
        refresh()
    }

    func refresh() {
        guard #available(iOS 16.1, *) else { systemActivities = []; return }
        systemActivities = Activity<RadioBroadcastAttributes>.activities.map { activity in
            "\(activity.attributes.pushwoosh.activityId) · \(String(describing: activity.activityState))"
        }
    }
}

// MARK: - Screen

struct RadioLiveActivityView: View {
    @StateObject private var controller = RestockController()

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    statusPill
                    ForEach(controller.items) { item in
                        itemRow(item)
                    }
                    systemCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .onAppear { controller.configure() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(PushMart.tangerine.opacity(0.16)).frame(width: 50, height: 50)
                Image(systemName: "bell.badge.fill").font(.system(size: 20, weight: .bold)).foregroundColor(PushMart.tangerine)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("RESTOCK REMINDERS")
                    .font(PushMart.label(13)).tracking(2).foregroundColor(PushMart.tangerine)
                Text("Get pinged the moment items are back")
                    .font(PushMart.body(14)).foregroundColor(PushMart.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 16)
    }

    private var statusPill: some View {
        Text(controller.statusLine)
            .font(PushMart.body(13)).foregroundColor(PushMart.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12).padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(PushMart.surface))
    }

    private func itemRow(_ item: RestockItem) -> some View {
        let scheduled = controller.isScheduled(item)
        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                Text(item.emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(PushMart.headline(16)).foregroundColor(PushMart.textPrimary)
                    Text("\(item.brand) · \(item.variant)")
                        .font(PushMart.body(12)).foregroundColor(PushMart.textSecondary).lineLimit(1)
                }
                Spacer()
                Text(scheduled ? "at \(controller.scheduledAt[item.id] ?? "")" : "+\(item.minutes) min")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(PushMart.textTertiary)
            }

            Button {
                scheduled ? controller.cancel(item) : controller.schedule(item)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: scheduled ? "checkmark.circle.fill" : "bell.badge")
                        .font(.system(size: 15, weight: .bold))
                    Text(scheduled ? "Reminder on · tap to cancel" : "Notify me  +\(item.minutes) min")
                        .font(PushMart.headline(15))
                }
                .foregroundColor(scheduled ? PushMart.textPrimary : PushMart.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    Capsule().fill(scheduled
                        ? AnyShapeStyle(PushMart.surfaceHi)
                        : AnyShapeStyle(PushMart.brandHorizontal))
                )
                .overlay(Capsule().strokeBorder(PushMart.stroke, lineWidth: scheduled ? 1 : 0))
            }
            .buttonStyle(.plain)
            .sdkNote("Pushwoosh.LiveActivities.schedule(attributes:contentState:at:...) throws",
                     "Schedules a future Live Activity that appears on the Lock Screen at the reminder time, or cancels the pending one.",
                     docs: "On appear the screen calls Pushwoosh.LiveActivities.setup(RadioBroadcastAttributes.self) once to register this activity type for lifecycle tracking. Scheduling with a future date needs iOS 26.",
                     calls: [
                        .init(code: "Pushwoosh.LiveActivities.schedule(attributes: attrs, contentState: state, at: start, alertTitle: ..., alertBody: ...)",
                              note: "Notify me - schedule the restock Live Activity to start at the item's offset time (+minutes)."),
                        .init(code: "Pushwoosh.LiveActivities.cancel(RadioBroadcastAttributes.self, activityId: item.id)",
                              note: "Tap to cancel - remove the pending reminder for this item using its activityId."),
                     ])
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(PushMart.surface)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1))
        )
    }

    private var systemCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scheduled (\(controller.systemActivities.count))")
                    .font(PushMart.headline(15)).foregroundColor(PushMart.textPrimary)
                Spacer()
                Button { controller.refresh() } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 13, weight: .bold))
                        .foregroundColor(PushMart.textPrimary).padding(8)
                        .background(Circle().fill(PushMart.surfaceHi))
                }
                Button { controller.endAll() } label: {
                    Text("Clear all").font(PushMart.label(12))
                        .foregroundColor(PushMart.danger).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Capsule().fill(PushMart.danger.opacity(0.18)))
                }
            }

            if controller.systemActivities.isEmpty {
                Text("No reminders scheduled yet")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(PushMart.textTertiary)
            } else {
                ForEach(controller.systemActivities, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(line.contains("pending") ? PushMart.tangerine : PushMart.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(PushMart.surface))
    }
}

#Preview {
    RadioLiveActivityView()
}
