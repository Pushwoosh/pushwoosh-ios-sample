//
//  InboxDataView.swift
//  PushMart
//

import SwiftUI
import PushwooshFramework

// Inbox data screen. Signature: drives the raw PWInbox message API directly —
// counts, load, per-message action/read/delete, bulk operations — plus the four
// inbox observers. Distinct from the InboxKit UI feed on the Offers tab, which
// wraps the same storage behind a prebuilt view controller.
struct InboxDataView: View {
    @State private var total: Int?
    @State private var unread: Int?
    @State private var noAction: Int?

    @State private var messages: [PWInboxMessageProtocol] = []
    @State private var loadedMessages = false

    @State private var observerTokens: [NSObjectProtocol] = []

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    countsCard
                    messagesCard
                    actionsCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .onAppear {
            refreshCounts()
            registerObservers()
        }
        .onDisappear(perform: removeObservers)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Inbox data").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("The raw PWInbox message API").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(.top, 4)
    }

    // MARK: Counts (messagesCount / unreadMessagesCount / messagesWithNoActionPerformedCount)

    private var countsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Message counts").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    Button { refreshCounts() } label: {
                        Text("Refresh").font(PushMart.label(13)).foregroundStyle(PushMart.coral)
                    }
                }
                statRow("Total", total, "tray.full.fill")
                Divider().overlay(PushMart.stroke)
                statRow("Unread", unread, "envelope.badge.fill")
                Divider().overlay(PushMart.stroke)
                statRow("No action taken", noAction, "hand.tap.fill")
            }
        }
        .sdkNote("PWInbox.messagesCount / unreadMessagesCount / messagesWithNoActionPerformedCount { }",
                 "Reads how many inbox messages there are: total, unread, and with no action taken yet.",
                 docs: "On appear this screen also registers four inbox observers so the counts and list stay live: addObserverForDidReceive(inPushNotificationCompletion:), addObserver(forUpdateMessagesCompletion:), addObserverForUnreadMessagesCount, and addObserverForNoActionPerformedMessagesCount. Each returns a token removed with PWInbox.removeObserver(_:) on disappear.",
                 calls: [
                    .init(code: "PWInbox.messagesCount { count, error in }",
                          note: "Total number of stored inbox messages."),
                    .init(code: "PWInbox.unreadMessagesCount { count, error in }",
                          note: "How many messages are still unread."),
                    .init(code: "PWInbox.messagesWithNoActionPerformedCount { count, error in }",
                          note: "Messages the user has not acted on yet.")
                 ])
    }

    private func statRow(_ label: String, _ value: Int?, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(PushMart.coral).frame(width: 20)
            Text(label).font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
            Spacer()
            Text(value.map { "\($0)" } ?? "—")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(PushMart.textPrimary)
        }
        .padding(.vertical, 2)
    }

    // MARK: Messages (loadMessages, per-row performAction/read/delete)

    private var messagesCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Messages").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                PushMartButton(title: loadedMessages ? "Reload messages" : "Load messages", icon: "arrow.down.circle") {
                    loadMessages()
                }
                .sdkNote("PWInbox.loadMessages { }",
                         "Loads the full inbox message list straight from PWInbox, with no InboxKit view controller.",
                         calls: [
                            .init(code: "PWInbox.loadMessages { loaded, error in }",
                                  note: "Returns every stored message, or an error if the load failed.")
                         ])
                if loadedMessages {
                    if messages.isEmpty {
                        Text("No inbox messages yet. Send one from the Pushwoosh dashboard, then reload.")
                            .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        ForEach(Array(messages.enumerated()), id: \.element.code) { idx, message in
                            messageRow(message)
                            if idx < messages.count - 1 { Divider().overlay(PushMart.stroke) }
                        }
                    }
                } else {
                    Text("Load the feed straight from PWInbox.loadMessages — no InboxKit view controller involved. Tap a row to run its action and mark it read; use the trash to delete it.")
                        .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .sdkNote("PWInbox.performActionForMessage(withCode:) / readMessages(withCodes:) / message(forCode:) / deleteMessages(withCodes:)",
                 "Per-row actions: tap a message to run its action and mark it read; tap the trash to delete it.",
                 calls: [
                    .init(code: "PWInbox.performActionForMessage(withCode: code)",
                          note: "Runs the tapped message's action (deep link, URL, or in-app)."),
                    .init(code: "PWInbox.readMessages(withCodes: [code])",
                          note: "Marks the tapped message as read."),
                    .init(code: "PWInbox.message(forCode: code)",
                          note: "Fetches the single message by code to read back its updated state."),
                    .init(code: "PWInbox.deleteMessages(withCodes: [code])",
                          note: "Deletes just that one message when its trash icon is tapped.")
                 ])
    }

    private func messageRow(_ message: PWInboxMessageProtocol) -> some View {
        HStack(alignment: .top, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle().fill(message.isRead ? PushMart.textTertiary : PushMart.coral)
                    .frame(width: 9, height: 9).padding(.top, 5)
                VStack(alignment: .leading, spacing: 3) {
                    Text(message.title.isEmpty ? "Untitled" : message.title)
                        .font(PushMart.headline(15)).foregroundStyle(PushMart.textPrimary)
                        .lineLimit(1)
                    if !message.message.isEmpty {
                        Text(message.message)
                            .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                            .lineLimit(2).multilineTextAlignment(.leading)
                    }
                    HStack(spacing: 8) {
                        Text(dateText(message.sendDate)).font(PushMart.body(11)).foregroundStyle(PushMart.textTertiary)
                        Text(message.isRead ? "READ" : "UNREAD")
                            .font(PushMart.label(10)).tracking(0.5)
                            .foregroundStyle(message.isRead ? PushMart.textTertiary : PushMart.coral)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { open(message) }
            Button { delete(message) } label: {
                Image(systemName: "trash").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PushMart.textTertiary).padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: Bulk actions (markAllMessagesAsRead / deleteAllReadMessages / resync)

    private var actionsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Bulk actions").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                PushMartButton(title: "Mark all read", icon: "checkmark.circle") { markAllRead() }
                    .sdkNote("PWInbox.markAllMessagesAsRead()",
                             "Marks every stored inbox message as read at once.",
                             calls: [
                                .init(code: "PWInbox.markAllMessagesAsRead()",
                                      note: "Flags all messages read in one call, then the counts refresh.")
                             ])
                PushMartButton(title: "Delete read", icon: "trash", style: .secondary) { deleteRead() }
                    .sdkNote("PWInbox.deleteAllReadMessages()",
                             "Deletes every message that has already been read.",
                             calls: [
                                .init(code: "PWInbox.deleteAllReadMessages()",
                                      note: "Removes all read messages, leaving unread ones in place.")
                             ])
                PushMartButton(title: "Resync for user", icon: "arrow.triangle.2.circlepath", style: .secondary) { resync() }
                    .sdkNote("PWInbox.resyncInboxForNewUserId()",
                             "Re-syncs the inbox after the user ID changes so it shows the new user's messages.",
                             calls: [
                                .init(code: "await PWInbox.resyncInboxForNewUserId()",
                                      note: "Async call - returns how many messages the current user now has.")
                             ])
                Text("These run straight through PWInbox and refresh the counts and list above.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: SDK calls

    private func refreshCounts() {
        PushwooshHelper.safeCall {
            PWInbox.messagesCount { count, error in
                DispatchQueue.main.async { if error == nil { total = count } }
            }
        }
        PushwooshHelper.safeCall {
            PWInbox.unreadMessagesCount { count, error in
                DispatchQueue.main.async { if error == nil { unread = count } }
            }
        }
        PushwooshHelper.safeCall {
            PWInbox.messagesWithNoActionPerformedCount { count, error in
                DispatchQueue.main.async { if error == nil { noAction = count } }
            }
        }
    }

    private func loadMessages() {
        PushwooshHelper.safeCall {
            PWInbox.loadMessages { loaded, error in
                DispatchQueue.main.async {
                    loadedMessages = true
                    if let error {
                        PushMartResult.shared.fail("Couldn't load", error.localizedDescription)
                        return
                    }
                    messages = loaded ?? []
                }
            }
        }
    }

    private func reload() {
        refreshCounts()
        if loadedMessages { loadMessages() }
    }

    private func open(_ message: PWInboxMessageProtocol) {
        guard let code = message.code else { return }
        PushwooshHelper.safeCall { PWInbox.performActionForMessage(withCode: code) }
        PushwooshHelper.safeCall { PWInbox.readMessages(withCodes: [code]) }
        let refreshed = PushwooshHelper.safeCall(nil) { PWInbox.message(forCode: code) }
        let title = refreshed?.title ?? message.title ?? ""
        PushMartResult.shared.success("Message opened", "\(title.isEmpty ? "Message" : title) marked as read.")
        reload()
    }

    private func delete(_ message: PWInboxMessageProtocol) {
        guard let code = message.code else { return }
        PushwooshHelper.safeCall { PWInbox.deleteMessages(withCodes: [code]) }
        let title = message.title ?? ""
        PushMartResult.shared.success("Message deleted", "Removed \"\(title.isEmpty ? code : title)\".")
        reload()
    }

    private func markAllRead() {
        PushwooshHelper.safeCall { PWInbox.markAllMessagesAsRead() }
        PushMartResult.shared.success("Marked all read", "Every stored message is now read.")
        reload()
    }

    private func deleteRead() {
        PushwooshHelper.safeCall { PWInbox.deleteAllReadMessages() }
        PushMartResult.shared.success("Cleared read", "Deleted every read message.")
        reload()
    }

    private func resync() {
        Task {
            await PushwooshHelper.safeCall {
                let count = await PWInbox.resyncInboxForNewUserId()
                DispatchQueue.main.async {
                    PushMartResult.shared.success("Inbox resynced", "\(count) messages for the current user.")
                    reload()
                }
            }
        }
    }

    // MARK: Observers

    private func registerObservers() {
        guard observerTokens.isEmpty else { return }
        let received = PushwooshHelper.safeCall(nil) {
            PWInbox.addObserverForDidReceive(inPushNotificationCompletion: { _ in
                DispatchQueue.main.async { reload() }
            })
        }
        let updated = PushwooshHelper.safeCall(nil) {
            PWInbox.addObserver(forUpdateMessagesCompletion: { _, _, _ in
                DispatchQueue.main.async { reload() }
            })
        }
        let unreadObserver = PushwooshHelper.safeCall(nil) {
            PWInbox.addObserverForUnreadMessagesCount { count in
                DispatchQueue.main.async { unread = Int(count) }
            }
        }
        let noActionObserver = PushwooshHelper.safeCall(nil) {
            PWInbox.addObserverForNoActionPerformedMessagesCount { count in
                DispatchQueue.main.async { noAction = Int(count) }
            }
        }
        observerTokens = [received, updated, unreadObserver, noActionObserver].compactMap { $0 }
    }

    private func removeObservers() {
        for token in observerTokens {
            PushwooshHelper.safeCall { PWInbox.removeObserver(token) }
        }
        observerTokens = []
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    InboxDataView()
}
