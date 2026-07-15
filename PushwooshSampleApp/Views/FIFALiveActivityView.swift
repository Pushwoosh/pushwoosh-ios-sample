//
//  FIFALiveActivityView.swift
//  PushMart
//
//  "Flash-sale drops": several upcoming product drops, each scheduled at a
//  different offset via Pushwoosh.LiveActivities.schedule(at:). A live readout of
//  Activity<FIFAMatchAttributes>.activities shows scheduled (pending) vs started
//  activities. The FIFAMatchAttributes type is reused as the shared LA payload;
//  its fields carry the drop's name/tagline/discount.
//

import SwiftUI
import ActivityKit
import PushwooshFramework
import PushwooshLiveActivities

// MARK: - Model

struct FlashDrop: Identifiable {
    let id: String          // used as the Pushwoosh activityId
    let name: String
    let tagline: String
    let code: String
    let emoji: String
    let category: String
    let discount: String
    let minutes: Int        // schedule offset from now
}

// MARK: - Controller

@MainActor
final class FlashDropController: ObservableObject {
    @Published var scheduledAt: [String: String] = [:]
    @Published var statusLine = "Schedule a drop and watch its countdown reach the Lock Screen"
    @Published var systemActivities: [String] = []

    let drops: [FlashDrop] = [
        FlashDrop(id: "drop_aeroknit", name: "AeroKnit Runner", tagline: "Members-only colorway",
                  code: "AERO", emoji: "👟", category: "Sneakers", discount: "-30%", minutes: 1),
        FlashDrop(id: "drop_pulsebuds", name: "Pulse Buds Pro", tagline: "Midnight edition",
                  code: "PULSE", emoji: "🎧", category: "Audio", discount: "-25%", minutes: 2),
        FlashDrop(id: "drop_chrono", name: "Chrono S3", tagline: "Titanium restock",
                  code: "CHRONO", emoji: "⌚️", category: "Watches", discount: "-20%", minutes: 3),
        FlashDrop(id: "drop_voyager", name: "Voyager Tote", tagline: "New season arrival",
                  code: "VOY", emoji: "👜", category: "Bags", discount: "-15%", minutes: 4)
    ]

    func configure() {
        if #available(iOS 16.1, *) {
            Pushwoosh.LiveActivities.setup(FIFAMatchAttributes.self)
        }
        refresh()
    }

    func isScheduled(_ drop: FlashDrop) -> Bool { scheduledAt[drop.id] != nil }

    func schedule(_ drop: FlashDrop) {
        guard #available(iOS 26.0, *) else {
            statusLine = "Scheduling needs iOS 26"
            return
        }

        let start = Date().addingTimeInterval(Double(drop.minutes) * 60)
        let label = start.formatted(date: .omitted, time: .shortened)

        let attrs = FIFAMatchAttributes(
            homeTeam: drop.name, awayTeam: drop.tagline,
            homeAbbr: drop.code, awayAbbr: drop.discount,
            homeFlag: drop.emoji, awayFlag: "🔥",
            competition: drop.category, venue: drop.discount,
            pushwoosh: PushwooshLiveActivityAttributeData(activityId: drop.id)
        )
        let state = FIFAMatchAttributes.ContentState(
            homeScore: 0, awayScore: 0,
            clock: "Drops \(label)",
            statusLine: "\(drop.name) drops \(label)",
            isLive: false, pushwoosh: nil
        )

        do {
            try Pushwoosh.LiveActivities.schedule(
                attributes: attrs, contentState: state, at: start,
                alertTitle: "\(drop.name) drop",
                alertBody: "\(drop.category) · \(drop.discount) starts at \(label)"
            )
            scheduledAt[drop.id] = label
            statusLine = "Scheduled \(drop.name) for \(label)  (+\(drop.minutes) min)"
        } catch {
            statusLine = "Schedule failed: \(error.localizedDescription)"
        }
        refresh()
    }

    func cancel(_ drop: FlashDrop) {
        Pushwoosh.LiveActivities.cancel(FIFAMatchAttributes.self, activityId: drop.id)
        scheduledAt[drop.id] = nil
        statusLine = "Cancelled \(drop.name)"
        refresh()
    }

    func endAll() {
        if #available(iOS 16.2, *) {
            for activity in Activity<FIFAMatchAttributes>.activities {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
        }
        scheduledAt.removeAll()
        statusLine = "Cleared all drops"
        refresh()
    }

    func refresh() {
        guard #available(iOS 16.1, *) else { systemActivities = []; return }
        systemActivities = Activity<FIFAMatchAttributes>.activities.map { activity in
            "\(activity.attributes.pushwoosh.activityId) · \(String(describing: activity.activityState))"
        }
    }
}

// MARK: - Screen

struct FIFALiveActivityView: View {
    @StateObject private var controller = FlashDropController()

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    statusPill
                    ForEach(controller.drops) { drop in
                        dropRow(drop)
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
                Circle().fill(PushMart.coral.opacity(0.16)).frame(width: 50, height: 50)
                Image(systemName: "flame.fill").font(.system(size: 22, weight: .bold)).foregroundColor(PushMart.coral)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("FLASH-SALE DROPS")
                    .font(PushMart.label(13)).tracking(2).foregroundColor(PushMart.coral)
                Text("Schedule a Lock Screen countdown")
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

    private func dropRow(_ drop: FlashDrop) -> some View {
        let scheduled = controller.isScheduled(drop)
        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                Text(drop.emoji).font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text(drop.name).font(PushMart.headline(16)).foregroundColor(PushMart.textPrimary)
                    Text("\(drop.category) · \(drop.tagline)")
                        .font(PushMart.body(12)).foregroundColor(PushMart.textSecondary).lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(drop.discount).font(PushMart.headline(15)).foregroundColor(PushMart.coral)
                    Text(scheduled ? "at \(controller.scheduledAt[drop.id] ?? "")" : "+\(drop.minutes) min")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(PushMart.textTertiary)
                }
            }

            Button {
                scheduled ? controller.cancel(drop) : controller.schedule(drop)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: scheduled ? "checkmark.circle.fill" : "calendar.badge.clock")
                        .font(.system(size: 15, weight: .bold))
                    Text(scheduled ? "Scheduled · tap to cancel" : "Remind me  +\(drop.minutes) min")
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
            .sdkNote("Pushwoosh.LiveActivities.schedule(attributes:contentState:at:) · cancel(_:activityId:)",
                     "Remind me schedules a future Lock Screen countdown for this drop; when it is already scheduled the same button cancels it.",
                     docs: "Pushwoosh.LiveActivities.setup(FIFAMatchAttributes.self) is called once on appear (in configure) to register the attributes type before anything can be scheduled. schedule throws and requires iOS 26; the drop id is passed as the activityId so the pending activity can be found and cancelled later.",
                     calls: [
                        .init(code: "try Pushwoosh.LiveActivities.schedule(attributes: attrs, contentState: state, at: start, alertTitle: \"\\(drop.name) drop\", alertBody: ...)",
                              note: "Remind me: schedules the Live Activity to start at the drop time (now + N min) with a Lock Screen alert. Needs iOS 26."),
                        .init(code: "Pushwoosh.LiveActivities.cancel(FIFAMatchAttributes.self, activityId: drop.id)",
                              note: "Tap when already scheduled: cancels the pending activity for this drop, keyed by the drop id used as its activityId.")
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
                Text("No drops scheduled yet")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(PushMart.textTertiary)
            } else {
                ForEach(controller.systemActivities, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(line.contains("pending") ? PushMart.coral : PushMart.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(PushMart.surface))
    }
}

#Preview {
    FIFALiveActivityView()
}
