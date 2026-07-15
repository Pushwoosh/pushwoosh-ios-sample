//
//  NotificationsView.swift
//  PushMart
//

import SwiftUI
import PushwooshFramework

// Reminders screen. Framed as a natural "remind me to come back" feature: pick
// what to be reminded about and when, and PushMart schedules a local notification.
struct NotificationsView: View {
    private struct Reminder: Identifiable {
        let id: String
        let chip: String
        let icon: String
        let title: String
        let body: String
    }
    private struct Delay: Identifiable {
        let id: String
        let label: String
        let seconds: TimeInterval
    }

    private let reminders: [Reminder] = [
        .init(id: "cart", chip: "My cart", icon: "cart.fill",
              title: "Your cart is waiting 🛒", body: "Come back and check out before your picks sell out."),
        .init(id: "wishlist", chip: "Wishlist", icon: "heart.fill",
              title: "Something you saved is popular", body: "Items in your wishlist are selling fast."),
        .init(id: "deals", chip: "Today's deals", icon: "flame.fill",
              title: "Don't miss today's deals 🔥", body: "Members-only offers are live right now.")
    ]
    private let delays: [Delay] = [
        .init(id: "10s", label: "10 seconds", seconds: 10),
        .init(id: "1m", label: "1 minute", seconds: 60),
        .init(id: "5m", label: "5 minutes", seconds: 300)
    ]

    @State private var reminderID = "cart"
    @State private var delayID = "10s"

    private var reminder: Reminder { reminders.first { $0.id == reminderID } ?? reminders[0] }
    private var delay: Delay { delays.first { $0.id == delayID } ?? delays[0] }

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    enablePushCard
                    preview
                    remindCard
                    clearCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Reminders").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("We'll nudge you when it matters").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(.top, 4)
    }

    // MARK: Enable push (on-demand, not at launch)

    private var enablePushCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Push notifications").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                Text("Turn on push to get order updates and members-only deals.")
                    .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                PushMartButton(title: "Enable notifications", icon: "bell.fill") {
                    AppDelegate.showPushPrimer()
                }
                .sdkNote("Pushwoosh.configure.pushPrimer",
                         "Shows the soft opt-in primer, then the system prompt and registration on accept.",
                         calls: [
                            .init(code: "pushPrimer.present { outcome in … }",
                                  note: "Presented on demand from this button, not automatically at launch."),
                         ])
            }
        }
    }

    // MARK: Live preview of the reminder

    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREVIEW").font(PushMart.label(11)).tracking(2).foregroundStyle(PushMart.textTertiary)
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(PushMart.brand).frame(width: 40, height: 40)
                    .overlay(Image(systemName: "bag.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(PushMart.ink))
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("PUSHMART").font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1).foregroundStyle(PushMart.textSecondary)
                        Spacer()
                        Text("in \(delay.label)").font(.system(size: 10, weight: .medium)).foregroundStyle(PushMart.textTertiary)
                    }
                    Text(reminder.title).font(PushMart.headline(14.5)).foregroundStyle(PushMart.textPrimary).lineLimit(1)
                    Text(reminder.body).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary).lineLimit(2)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(PushMart.surfaceHi)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
        }
    }

    // MARK: Compose the reminder naturally

    private var remindCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Remind me about").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                chipRow(reminders.map { ($0.id, $0.chip, $0.icon) }, selected: reminderID) { reminderID = $0 }

                Text("In").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                chipRow(delays.map { ($0.id, $0.label, nil) }, selected: delayID) { delayID = $0 }

                PushMartButton(title: "Remind me", icon: "bell.badge.fill") {
                    Notifications.shared.showLocalNotification(title: reminder.title, body: reminder.body, delay: delay.seconds)
                    PushMartResult.shared.success("Reminder set", "We'll nudge you in \(delay.label).")
                }
                Text("Delivered right here on your device — allow notifications when prompted.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func chipRow(_ items: [(String, String, String?)], selected: String, onTap: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.0) { item in
                    Button { onTap(item.0) } label: {
                        PushMartChip(title: item.1, selected: selected == item.0, icon: item.2)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Clear

    private var clearCard: some View {
        PushMartCard {
            PushMartButton(title: "Clear reminders", icon: "bell.slash.fill", style: .ghost) {
                PushNotificationManager.clearNotificationCenter()
                PushMartResult.shared.success("Cleared", "Your notification center is empty.")
            }
            .sdkNote("PushNotificationManager.clearNotificationCenter()",
                     "Removes PushMart's already-delivered notifications from Notification Center.",
                     calls: [
                        .init(code: "PushNotificationManager.clearNotificationCenter()",
                              note: "Clears the app's delivered notifications from Notification Center.")
                     ])
        }
    }
}

#Preview {
    NotificationsView()
}
