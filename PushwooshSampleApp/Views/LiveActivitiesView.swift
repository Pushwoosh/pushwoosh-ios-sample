//
//  LiveActivitiesView.swift
//  PushwooshSampleApp
//

import SwiftUI
import ActivityKit
import PushwooshFramework
import PushwooshLiveActivities

@MainActor
final class ManualLiveActivityController: ObservableObject {
    static let shared = ManualLiveActivityController()

    @Published var activityId: String = ""
    @Published var lastPushToken: String = ""
    @Published var status: String = "Idle"
    @Published var isRunning: Bool = false
    @Published var pushToStartStatus: String = "Off"

    private var activity: Activity<LiveActivityDemoAttributes>?
    private var tokenObserver: Task<Void, Never>?
    private var pushToStartObserver: Task<Void, Never>?

    // Register a push-to-start token so a campaign can start the order card remotely,
    // even when the app is closed (iOS 17.2+).
    func enablePushToStart() {
        guard #available(iOS 17.2, *) else {
            pushToStartStatus = "Needs iOS 17.2"
            return
        }
        guard pushToStartObserver == nil else {
            pushToStartStatus = "Already on"
            return
        }
        pushToStartStatus = "Waiting for token…"
        pushToStartObserver = Task { [weak self] in
            for await tokenData in Activity<LiveActivityDemoAttributes>.pushToStartTokenUpdates {
                let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                Pushwoosh.LiveActivities.sendPushToStartLiveActivity(token: hex) { error in
                    DispatchQueue.main.async {
                        self?.pushToStartStatus = error == nil
                            ? "On — campaigns can start your order card"
                            : "Error: \(error!.localizedDescription)"
                    }
                }
            }
        }
    }

    func start() {
        let id = activityId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else {
            status = "Enter Activity ID first"
            return
        }
        guard activity == nil else {
            status = "Already running — Stop first"
            return
        }

        let attributes = LiveActivityDemoAttributes(pushwoosh: PushwooshLiveActivityAttributeData(activityId: id))
        let initialState = LiveActivityDemoAttributes.ContentState(
            status: "Packed & ready",
            estimatedTime: "1 day",
            emoji: "📦",
            pushwoosh: nil
        )

        do {
            let new = try Activity<LiveActivityDemoAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: .token
            )
            activity = new
            isRunning = true
            status = "Activity started (system id: \(new.id))"
            observeToken(for: new, businessId: id)
        } catch {
            status = "Request error: \(error.localizedDescription)"
        }
    }

    // Start live order tracking right after checkout (fresh "Order confirmed" card).
    func startOrder(id: String) {
        guard !PushwooshHelper.isUITesting else { return }
        activityId = id
        guard activity == nil else {
            status = "An order is already being tracked"
            return
        }
        let attributes = LiveActivityDemoAttributes(pushwoosh: PushwooshLiveActivityAttributeData(activityId: id))
        let initialState = LiveActivityDemoAttributes.ContentState(
            status: "Order confirmed", estimatedTime: "2 days", emoji: "🧾", pushwoosh: nil
        )
        do {
            let new = try Activity<LiveActivityDemoAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: .token
            )
            activity = new
            isRunning = true
            status = "Order tracking started (system id: \(new.id))"
            observeToken(for: new, businessId: id)
        } catch {
            status = "Live Activity error: \(error.localizedDescription)"
        }
    }

    func stop() {
        print("[ManualLA] stop() pressed, activity=\(String(describing: activity?.id)), id=\(activityId)")
        guard let live = activity else {
            status = "No active activity to stop"
            return
        }
        let businessId = activityId.trimmingCharacters(in: .whitespaces)

        Task {
            print("[ManualLA] calling activity.end(nil, .immediate) on \(live.id)")
            await live.end(nil, dismissalPolicy: .immediate)
            print("[ManualLA] activity.end returned")
        }

        if lastPushToken.isEmpty {
            status = "Cancelled locally — no token was registered with Pushwoosh yet"
        } else {
            Pushwoosh.LiveActivities.stopLiveActivity(activityId: businessId) { error in
                DispatchQueue.main.async {
                    if let error {
                        self.status = "stopLiveActivity error: \(error.localizedDescription)"
                    } else {
                        self.status = "Stop request sent to Pushwoosh"
                    }
                }
            }
        }

        tokenObserver?.cancel()
        tokenObserver = nil
        activity = nil
        isRunning = false
    }

    private func observeToken(for activity: Activity<LiveActivityDemoAttributes>, businessId: String) {
        tokenObserver?.cancel()
        tokenObserver = Task { [weak self] in
            for await tokenData in activity.pushTokenUpdates {
                let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                await MainActor.run {
                    guard let self else { return }
                    self.lastPushToken = hex
                    self.status = "Got push token (\(hex.count) chars) — sending to Pushwoosh…"
                }

                Pushwoosh.LiveActivities.startLiveActivity(token: hex, activityId: businessId) { error in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if let error {
                            self.status = "startLiveActivity error: \(error.localizedDescription)"
                        } else {
                            self.status = "Activity token registered with Pushwoosh ✓"
                        }
                    }
                }
            }
        }
    }
}

struct LiveActivitiesView: View {
    @ObservedObject private var controller = ManualLiveActivityController.shared
    @State private var showFIFA = false
    @State private var showRadio = false

    var body: some View {
        ZStack {
            PushMartBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header

                    startCard

                    statusCard

                    stopCard

                    pushToStartCard

                    defaultCard

                    showcasesSection

                    howItWorksCard

                    Spacer(minLength: 96)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .fullScreenCover(isPresented: $showFIFA) {
            ShowcaseContainer { FIFALiveActivityView() }
        }
        .fullScreenCover(isPresented: $showRadio) {
            ShowcaseContainer { RadioLiveActivityView() }
        }
    }

    private var showcasesSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("MORE LIVE UPDATES")
                    .font(PushMart.label(12)).tracking(2).foregroundColor(PushMart.textTertiary)
                Spacer()
            }
            .padding(.horizontal, 4)

            ShowcaseCard(
                icon: "flame.fill",
                iconColors: [PushMart.coral, PushMart.tangerine],
                title: "Flash-sale drops",
                subtitle: "Schedule Lock Screen countdowns for upcoming drops",
                badge: "🔥 4 drops"
            ) { showFIFA = true }

            ShowcaseCard(
                icon: "bell.badge.fill",
                iconColors: [PushMart.tangerine, PushMart.coral],
                title: "Restock reminders",
                subtitle: "Get pinged the moment your saved items are back",
                badge: "🔔 4 items"
            ) { showRadio = true }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Orders")
                    .font(PushMart.display(32))
                    .foregroundStyle(PushMart.textPrimary)

                Text("Track deliveries live on your Lock Screen")
                    .font(PushMart.body(13))
                    .foregroundColor(PushMart.textSecondary)
            }
            Spacer()

            Circle()
                .fill(PushMart.brand)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(PushMart.ink)
                        .font(.system(size: 20, weight: .bold))
                )
        }
        .padding(.top, 4)
    }

    private var startCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Track an order")
                    .font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)

                PushMartField(placeholder: "ORDER NUMBER", text: $controller.activityId, icon: "number")

                PushMartButton(
                    title: controller.isRunning ? "Tracking active" : "Start live tracking",
                    icon: controller.isRunning ? "checkmark.circle.fill" : "location.fill",
                    style: controller.isRunning ? .secondary : .primary
                ) {
                    controller.start()
                }
                .sdkNote(
                    "Pushwoosh.LiveActivities.startLiveActivity(token:activityId:)",
                    "Pins a live order card to the Lock Screen and registers it with Pushwoosh so campaigns can update it over the air.",
                    docs: "The activity type LiveActivityDemoAttributes is registered once at app launch with Pushwoosh.LiveActivities.setup(LiveActivityDemoAttributes.self). ActivityKit owns the card: the app calls Activity.request(pushType: .token) to start it, then waits on the activity's pushTokenUpdates stream. When iOS issues a per-activity push token, the token observer forwards it to Pushwoosh so the backend can push updates to this exact card.",
                    calls: [
                        .init(code: "try Activity<LiveActivityDemoAttributes>.request(attributes:contentState:pushType: .token)",
                              note: "ActivityKit starts the live card and asks iOS for a push token for it."),
                        .init(code: "Pushwoosh.LiveActivities.startLiveActivity(token: hex, activityId: businessId) { error in }",
                              note: "In the pushTokenUpdates observer: registers the card's push token with Pushwoosh under your order number so the backend can send updates.")
                    ])

                Text("Pins a live delivery card to your Lock Screen and Dynamic Island, updated in real time even when PushMart is closed.")
                    .font(PushMart.body(13))
                    .foregroundColor(PushMart.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    private var statusCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("STATUS")
                    .font(PushMart.label(12)).tracking(1.5).foregroundColor(PushMart.textTertiary)

                Text(controller.status)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(PushMart.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !controller.lastPushToken.isEmpty {
                    Divider().overlay(PushMart.stroke)
                    Text("Live Activity push token")
                        .font(PushMart.label(11)).foregroundColor(PushMart.textTertiary).tracking(1.5)
                    Text(controller.lastPushToken)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(PushMart.success)
                        .textSelection(.enabled)
                        .lineLimit(3)
                        .truncationMode(.middle)
                }
            }
        }
    }

    private var stopCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                PushMartButton(title: "Stop tracking", icon: "stop.fill", style: .secondary) {
                    controller.stop()
                }
                .sdkNote(
                    "Pushwoosh.LiveActivities.stopLiveActivity(activityId:)",
                    "Removes the live delivery card and tells Pushwoosh to stop sending updates for this order.",
                    docs: "Two steps: ActivityKit dismisses the card locally, then Pushwoosh is told to stop pushing updates for it. If no push token was registered yet the card is only cancelled locally and no stop request is sent.",
                    calls: [
                        .init(code: "await activity.end(nil, dismissalPolicy: .immediate)",
                              note: "ActivityKit removes the live card from the Lock Screen and Dynamic Island right away."),
                        .init(code: "Pushwoosh.LiveActivities.stopLiveActivity(activityId: businessId) { error in }",
                              note: "Tells Pushwoosh to stop sending remote updates for this order number.")
                    ])
                Text("Removes the live delivery card and tells Pushwoosh to stop sending updates for this order.")
                    .font(PushMart.body(13))
                    .foregroundColor(PushMart.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    private var pushToStartCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Remote order tracking").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                Text("Let PushMart start your live order card from a campaign — even when the app is closed.")
                    .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                PushMartButton(title: "Enable remote start", icon: "antenna.radiowaves.left.and.right", style: .secondary) {
                    controller.enablePushToStart()
                }
                .sdkNote(
                    "Pushwoosh.LiveActivities.sendPushToStartLiveActivity(token:)",
                    "Registers a push-to-start token so a campaign can start your live order card, even when PushMart is closed (iOS 17.2+).",
                    docs: "The app subscribes to the attribute type's pushToStartTokenUpdates stream. iOS issues one push-to-start token per activity type; the observer forwards it to Pushwoosh so a campaign can start a brand-new Live Activity remotely without the app running.",
                    calls: [
                        .init(code: "for await tokenData in Activity<LiveActivityDemoAttributes>.pushToStartTokenUpdates",
                              note: "Waits for iOS to issue the push-to-start token for this activity type."),
                        .init(code: "Pushwoosh.LiveActivities.sendPushToStartLiveActivity(token: hex) { error in }",
                              note: "Sends the push-to-start token to Pushwoosh so a campaign can launch the order card remotely.")
                    ])
                Text(controller.pushToStartStatus)
                    .font(.system(size: 12, design: .monospaced)).foregroundStyle(PushMart.textTertiary)
            }
        }
    }

    private var defaultCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Default live activity").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                Text("Starts a live card using the SDK's bundled DefaultLiveActivityAttributes — no custom attributes struct needed. The widget renders straight from the attributes and content dictionaries you pass in.")
                    .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                PushMartButton(title: "Start default activity", icon: "shippingbox.fill", style: .primary) {
                    if #available(iOS 16.1, *) {
                        PushwooshHelper.safeCall {
                            Pushwoosh.LiveActivities.defaultStart(
                                "pushmart-default",
                                attributes: ["title": "PushMart order"],
                                content: ["status": "Preparing", "eta": "15 min"]
                            ) { error in
                                DispatchQueue.main.async {
                                    if let error {
                                        PushMartResult.shared.fail("Default activity failed", error.localizedDescription)
                                    } else {
                                        PushMartResult.shared.success("Default activity started", "Uses DefaultLiveActivityAttributes")
                                    }
                                }
                            }
                        }
                    } else {
                        PushMartResult.shared.fail("Needs iOS 16.1", "Default Live Activities require iOS 16.1+")
                    }
                }
                .sdkNote(
                    "Pushwoosh.LiveActivities.defaultStart(_:attributes:content:)",
                    "Starts a live card using the SDK's bundled attributes - no custom attributes struct needed.",
                    docs: "The default activity type is registered once at app launch with Pushwoosh.LiveActivities.defaultSetup(). The widget renders straight from the attributes and content dictionaries you pass in, so you can start a card entirely from plain values.",
                    calls: [
                        .init(code: "Pushwoosh.LiveActivities.defaultStart(\"pushmart-default\", attributes: [\"title\": \"PushMart order\"], content: [\"status\": \"Preparing\", \"eta\": \"15 min\"]) { error in }",
                              note: "Starts the bundled DefaultLiveActivityAttributes card under the id pushmart-default with the given title, status and ETA.")
                    ])

                PushMartButton(title: "Stop default activity", icon: "stop.fill", style: .secondary) {
                    PushwooshHelper.safeCall {
                        Pushwoosh.LiveActivities.stopLiveActivity(activityId: "pushmart-default")
                    }
                    PushMartResult.shared.success("Default activity stopped", "Stop request sent for pushmart-default")
                }
                .sdkNote(
                    "Pushwoosh.LiveActivities.stopLiveActivity(activityId:)",
                    "Stops the default order card and tells Pushwoosh to stop updating it.",
                    calls: [
                        .init(code: "Pushwoosh.LiveActivities.stopLiveActivity(activityId: \"pushmart-default\")",
                              note: "Ends the default activity started under the id pushmart-default.")
                    ])
            }
        }
    }

    private var howItWorksCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("How live tracking works")
                    .font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    InfoNoteRow(icon: "1.circle.fill",
                                text: "Start tracking and PushMart pins a live card to your Lock Screen",
                                color: PushMart.coral)
                    InfoNoteRow(icon: "2.circle.fill",
                                text: "The card registers securely so updates arrive over the air",
                                color: PushMart.tangerine)
                    InfoNoteRow(icon: "3.circle.fill",
                                text: "As your order is packed, shipped and delivered the card updates itself",
                                color: PushMart.success)
                    InfoNoteRow(icon: "4.circle.fill",
                                text: "Stop tracking any time to remove the card",
                                color: Color(rgb: 0x64D2FF))
                }
            }
        }
    }
}

struct ShowcaseCard: View {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let badge: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation { isPressed = false }
                action()
            }
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: iconColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: iconColors.last!.opacity(0.45), radius: 10, x: 0, y: 5)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12.5))
                        .foregroundColor(.white.opacity(0.6))
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)

                    Text(badge)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(iconColors.last!.opacity(0.22)))
                        .overlay(Capsule().strokeBorder(iconColors.last!.opacity(0.4), lineWidth: 1))
                        .padding(.top, 3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [iconColors.last!.opacity(0.5), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct ShowcaseContainer<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(11)
                    .background(Circle().fill(.white.opacity(0.15)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            }
            .padding(.trailing, 20)
            .padding(.top, 8)
        }
    }
}

#Preview {
    LiveActivitiesView()
}
