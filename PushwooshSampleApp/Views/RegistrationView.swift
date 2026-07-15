//
//  RegistrationView.swift
//  PushMart
//

import SwiftUI
import PushwooshFramework
import UserNotifications

// Push notifications screen. The signature is a stack of realistic PushMart
// notification banners — the product's own artifact — showing what the shopper
// will receive. Turning notifications on registers; the banners light up. The
// status "get" (getPushToken / getHWID / UN settings) is surfaced inline as
// "Delivery details", not an alert.
struct RegistrationView: View {
    @AppStorage("pushNotificationEnabled") private var pushNotificationEnabled = false
    @State private var showNotificationStatus = false
    @State private var notificationStatus: [AnyHashable: Any] = [:]
    @State private var provisionalOn = false

    private struct SamplePush: Identifiable {
        let id = UUID()
        let title: String
        let body: String
        let time: String
    }
    private let samples: [SamplePush] = [
        .init(title: "Order shipped 📦", body: "Your AeroKnit Runner is on the way — track it live.", time: "now"),
        .init(title: "Flash sale is live 🔥", body: "Members get up to 40% off for the next 3 hours.", time: "2m ago"),
        .init(title: "Back in stock", body: "Pulse Buds Pro just returned in Midnight.", time: "1h ago")
    ]

    var body: some View {
        ZStack {
            PushMartBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    previewStack
                    enableCard
                    detailsCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .onAppear {
            checkNotificationStatus()
            provisionalOn = PushwooshHelper.safeCall(false) {
                Pushwoosh.configure.getAdditionalAuthorizationOptions().contains(.provisional)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Notifications").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("What lands on your Lock Screen")
                .font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(.top, 4)
    }

    // MARK: Signature — sample push banners

    private var previewStack: some View {
        ZStack {
            VStack(spacing: 10) {
                ForEach(samples) { banner(for: $0) }
            }
            .opacity(pushNotificationEnabled ? 1 : 0.32)
            .blur(radius: pushNotificationEnabled ? 0 : 1.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: pushNotificationEnabled)

            if !pushNotificationEnabled {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 26, weight: .bold)).foregroundStyle(PushMart.textPrimary)
                    Text("Notifications are off")
                        .font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                    Text("Turn them on to get order updates,\ndrops and members-only deals.")
                        .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                        .multilineTextAlignment(.center)
                    Button { pushNotificationEnabled = true } label: {
                        Text("Turn on").font(PushMart.headline(15)).foregroundStyle(PushMart.ink)
                            .padding(.horizontal, 22).padding(.vertical, 11)
                            .background(Capsule().fill(PushMart.brandHorizontal))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                    .sdkNote("Pushwoosh.configure.registerForPushNotifications()",
                             "Flips the switch on, which registers this device.",
                             calls: [
                                .init(code: "registerForPushNotifications()",
                                      note: "Asks for notification permission and registers the device with Pushwoosh.")
                             ])
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(PushMart.ink.opacity(0.55)))
            }
        }
    }

    private func banner(for push: SamplePush) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(PushMart.brand)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "bag.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(PushMart.ink))
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("PUSHMART").font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1).foregroundStyle(PushMart.textSecondary)
                    Spacer()
                    Text(push.time).font(.system(size: 10, weight: .medium)).foregroundStyle(PushMart.textTertiary)
                }
                Text(push.title).font(PushMart.headline(14.5)).foregroundStyle(PushMart.textPrimary).lineLimit(1)
                Text(push.body).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary).lineLimit(2)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(PushMart.surfaceHi)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
    }

    // MARK: Enable control

    private var enableCard: some View {
        PushMartCard {
            HStack(spacing: 14) {
                Circle().fill(pushNotificationEnabled ? PushMart.success.opacity(0.18) : PushMart.surfaceHi)
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: pushNotificationEnabled ? "bell.badge.fill" : "bell.slash.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(pushNotificationEnabled ? PushMart.success : PushMart.textTertiary))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Push notifications").font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                    Text(pushNotificationEnabled ? "On · you're all set" : "Off")
                        .font(PushMart.body(13))
                        .foregroundStyle(pushNotificationEnabled ? PushMart.success : PushMart.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $pushNotificationEnabled)
                    .labelsHidden()
                    .tint(PushMart.coral)
                    .onChange(of: pushNotificationEnabled) { _, newValue in
                        setPushEnabled(newValue)
                    }
            }
        }
        .sdkNote("Pushwoosh.configure.registerForPushNotifications()",
                 "Turns push on or off for this device.",
                 calls: [
                    .init(code: "registerForPushNotifications()",
                          note: "On - asks for permission and registers the device with Pushwoosh."),
                    .init(code: "unregisterForPushNotifications()",
                          note: "Off - unregisters the device so it stops receiving pushes.")
                 ])
    }

    // MARK: Delivery details (the status "get", inline)

    private var detailsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Delivery details").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    Button { Task { await loadNotificationStatus() } } label: {
                        Text(showNotificationStatus ? "Refresh" : "Check status")
                            .font(PushMart.label(13)).foregroundStyle(PushMart.coral)
                    }
                }
                .sdkNote("Pushwoosh.sharedInstance().getPushToken()",
                         "Reads the push token, device id and Pushwoosh's notification status.",
                         calls: [
                            .init(code: "Pushwoosh.sharedInstance().getPushToken()",
                                  note: "Current APNs push token, or nil if the device isn't registered."),
                            .init(code: "Pushwoosh.configure.getHWID()",
                                  note: "Pushwoosh device (hardware) id for this install."),
                            .init(code: "Pushwoosh.configure.getRemoteNotificationStatus()",
                                  note: "Pushwoosh's own view of whether pushes are enabled and the notification type.")
                         ])

                if showNotificationStatus {
                    detailRow("Permission", value(for: "authorizationStatus"),
                              tint: value(for: "authorizationStatus") == "Authorized" ? PushMart.success : PushMart.warning)
                    detailRow("Push token", value(for: "pushToken"))
                    detailRow("Device ID", value(for: "hwid"))
                    detailRow("Alerts · Sound · Badge",
                              "\(value(for: "alertSetting")) · \(value(for: "soundSetting")) · \(value(for: "badgeSetting"))")
                    detailRow("Pushwoosh reports", value(for: "remoteStatus"))
                } else {
                    Text("Check the current permission, push token and device id registered with PushMart.")
                        .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider().overlay(PushMart.stroke)

                PushMartButton(title: "Re-register this device", icon: "bell.badge.fill", style: .secondary) {
                    PushwooshHelper.safeCall {
                        Pushwoosh.configure.registerForPushNotifications { token, error in
                            DispatchQueue.main.async {
                                if let error { PushMartResult.shared.fail("Register failed", error.localizedDescription) }
                                else { PushMartResult.shared.success("Registered", token ?? "") }
                            }
                        }
                    }
                }
                .sdkNote("Pushwoosh.configure.registerForPushNotifications { token, error in }",
                         "Registers again and reports the resulting token.",
                         calls: [
                            .init(code: "registerForPushNotifications { token, error in … }",
                                  note: "Completion variant - returns the APNs token on success or an error.")
                         ])
                PushMartButton(title: "Unregister", icon: "bell.slash.fill", style: .ghost) {
                    Task { await PushwooshHelper.safeCall { try? await Pushwoosh.configure.unregisterForPushNotifications() } }
                }
                .sdkNote("Pushwoosh.configure.unregisterForPushNotifications()",
                         "Stops this device from receiving pushes.",
                         calls: [
                            .init(code: "try await unregisterForPushNotifications()",
                                  note: "Async variant - unregisters the device from Pushwoosh.")
                         ])
                PushMartButton(title: "Clear delivered pushes", icon: "xmark.bin.fill", style: .ghost) {
                    PushwooshHelper.safeCall { Pushwoosh.configure.clearNotificationCenter() }
                    PushMartResult.shared.success("Cleared", "Removed delivered PushMart notifications.")
                }
                .sdkNote("Pushwoosh.configure.clearNotificationCenter()",
                         "Removes PushMart's delivered notifications from Notification Center.",
                         calls: [
                            .init(code: "clearNotificationCenter()",
                                  note: "Clears the app's already-delivered notifications from Notification Center.")
                         ])
                PushMartButton(title: "Preview foreground banner", icon: "rectangle.badge.checkmark", style: .secondary) {
                    PushwooshHelper.safeCall {
                        Pushwoosh.ForegroundPush.showForegroundPush(userInfo: [
                            "aps": ["alert": ["title": "PushMart", "body": "Members get 40% off for the next 3 hours 🔥"]]
                        ])
                    }
                }
                .sdkNote("Pushwoosh.ForegroundPush.showForegroundPush(userInfo:)",
                         "Shows an in-app banner for a push while the app is open.",
                         calls: [
                            .init(code: "ForegroundPush.showForegroundPush(userInfo: [\"aps\": [\"alert\": …]])",
                                  note: "Renders the given push payload as a foreground banner without a real notification.")
                         ])

                Toggle(isOn: $provisionalOn) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ask quietly (provisional)").font(PushMart.body(14)).foregroundStyle(PushMart.textPrimary)
                        Text("Adds .provisional to the authorization request — set before registering.")
                            .font(PushMart.body(12)).foregroundStyle(PushMart.textTertiary)
                    }
                }
                .tint(PushMart.coral)
                .onChange(of: provisionalOn) { _, newValue in
                    PushwooshHelper.safeCall {
                        Pushwoosh.configure.setAdditionalAuthorizationOptions(newValue ? [.provisional] : [])
                    }
                }
                .sdkNote("Pushwoosh.configure.setAdditionalAuthorizationOptions(_:)",
                         "Adds .provisional so permission is requested quietly.",
                         calls: [
                            .init(code: "setAdditionalAuthorizationOptions([.provisional])",
                                  note: "On - the next registration asks quietly, without a permission prompt."),
                            .init(code: "setAdditionalAuthorizationOptions([])",
                                  note: "Off - clears the extra options; registration prompts normally."),
                            .init(code: "getAdditionalAuthorizationOptions()",
                                  note: "Read on appear to restore the toggle's state.")
                         ])
            }
        }
    }

    private func detailRow(_ label: String, _ value: String, tint: Color = PushMart.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased()).font(PushMart.label(11)).tracking(1).foregroundStyle(PushMart.textTertiary)
            Text(value).font(.system(size: 13, design: .monospaced)).foregroundStyle(tint)
                .lineLimit(2).truncationMode(.middle).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func value(for key: String) -> String {
        (notificationStatus[key] as? String) ?? "—"
    }

    // MARK: Actions — SDK contract preserved

    private func setPushEnabled(_ enabled: Bool) {
        if enabled {
            PushwooshHelper.safeCall {
                Pushwoosh.configure.registerForPushNotifications()
            }
        } else {
            Task {
                await PushwooshHelper.safeCall {
                    try? await Pushwoosh.configure.unregisterForPushNotifications()
                }
            }
        }
    }

    private func checkNotificationStatus() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            DispatchQueue.main.async {
                pushNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func loadNotificationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        var status: [AnyHashable: Any] = [:]

        switch settings.authorizationStatus {
        case .authorized:     status["authorizationStatus"] = "Authorized"
        case .denied:         status["authorizationStatus"] = "Denied"
        case .notDetermined:  status["authorizationStatus"] = "Not Determined"
        case .provisional:    status["authorizationStatus"] = "Provisional"
        case .ephemeral:      status["authorizationStatus"] = "Ephemeral"
        @unknown default:     status["authorizationStatus"] = "Unknown"
        }

        status["alertSetting"] = settings.alertSetting == .enabled ? "On" : "Off"
        status["soundSetting"] = settings.soundSetting == .enabled ? "On" : "Off"
        status["badgeSetting"] = settings.badgeSetting == .enabled ? "On" : "Off"

        let pushToken = PushwooshHelper.safeCall(nil) {
            Pushwoosh.sharedInstance().getPushToken()
        }
        status["pushToken"] = pushToken ?? "Not registered"

        let hwid = PushwooshHelper.safeCall("") {
            Pushwoosh.configure.getHWID()
        }
        status["hwid"] = hwid

        let remote = PushwooshHelper.safeCall([AnyHashable: Any]()) {
            Pushwoosh.configure.getRemoteNotificationStatus() ?? [:]
        }
        if let enabled = remote["enabled"] {
            let on = "\(enabled)" == "1" || "\(enabled)".lowercased() == "true"
            status["remoteStatus"] = on ? "Enabled (type \(remote["type"] ?? "—"))" : "Disabled"
        } else {
            status["remoteStatus"] = remote.isEmpty ? "—" : "\(remote.count) field(s)"
        }

        DispatchQueue.main.async {
            self.notificationStatus = status
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                self.showNotificationStatus = true
            }
        }
    }
}

#Preview {
    RegistrationView()
}
