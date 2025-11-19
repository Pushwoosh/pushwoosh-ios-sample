//
//  RegistrationView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework
import UserNotifications

struct RegistrationView: View {
    @AppStorage("pushNotificationEnabled") private var pushNotificationEnabled = false
    @State private var showNotificationStatus = false
    @State private var notificationStatus: [AnyHashable: Any] = [:]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.2, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("REGISTRATION")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Push Notifications Setup")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Register for Push Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "bell.badge.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Push Notifications")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text(pushNotificationEnabled ? "Enabled" : "Disabled")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(pushNotificationEnabled ? .green : .red.opacity(0.7))
                                }

                                Spacer()

                                Toggle("", isOn: $pushNotificationEnabled)
                                    .tint(.blue)
                                    .scaleEffect(0.9)
                                    .onChange(of: pushNotificationEnabled) { oldValue, newValue in
                                        print("🔴 Toggle changed from \(oldValue) to \(newValue)")
                                        print("🔴 isDebugMode: \(PushwooshHelper.isDebugMode)")
                                        print("🔴 isUITesting: \(PushwooshHelper.isUITesting)")

                                        if newValue {
                                            print("🔴 Calling registerForPushNotifications")
                                            PushwooshHelper.safeCall {
                                                Pushwoosh.configure.registerForPushNotifications()
                                            }
                                            print("🔴 After registerForPushNotifications")
                                        } else {
                                            print("🔴 Calling unregisterForPushNotifications")
                                            Task {
                                                await PushwooshHelper.safeCall {
                                                    try? await Pushwoosh.configure.unregisterForPushNotifications()
                                                }
                                                print("🔴 After unregisterForPushNotifications")
                                            }
                                        }
                                    }
                                    .onAppear {
                                        checkNotificationStatus()
                                    }
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Enable or disable push notifications for this device. When enabled, you will receive notifications from Pushwoosh.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Manual Register Button Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "bell.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Manual Registration")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernButton(
                                title: "Register for Push",
                                icon: "bell.badge.fill",
                                gradient: [.purple, .pink]
                            ) {
                                PushwooshHelper.safeCall {
                                    Pushwoosh.configure.registerForPushNotifications()
                                }
                            }

                            ModernButton(
                                title: "Unregister from Push",
                                icon: "bell.slash.fill",
                                gradient: [.gray, .secondary]
                            ) {
                                Task {
                                    await PushwooshHelper.safeCall {
                                        try? await Pushwoosh.configure.unregisterForPushNotifications()
                                    }
                                }
                            }
                        }
                    }

                    // Notification Status Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("Notification Status")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernButton(
                                title: "Get Remote Notification Status",
                                icon: "checklist",
                                gradient: [.cyan, .blue]
                            ) {
                                Task {
                                    await loadNotificationStatus()
                                }
                            }
                            .alert(isPresented: $showNotificationStatus) {
                                Alert(
                                    title: Text("NOTIFICATION STATUS"),
                                    message: Text(formatNotificationStatus(notificationStatus)),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
            }
        }
    }

    private func checkNotificationStatus() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            DispatchQueue.main.async {
                // Update toggle based on actual notification authorization status
                pushNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func loadNotificationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        var status: [AnyHashable: Any] = [:]

        // Authorization status
        switch settings.authorizationStatus {
        case .authorized:
            status["authorizationStatus"] = "Authorized"
        case .denied:
            status["authorizationStatus"] = "Denied"
        case .notDetermined:
            status["authorizationStatus"] = "Not Determined"
        case .provisional:
            status["authorizationStatus"] = "Provisional"
        case .ephemeral:
            status["authorizationStatus"] = "Ephemeral"
        @unknown default:
            status["authorizationStatus"] = "Unknown"
        }

        // Alert settings
        status["alertSetting"] = settings.alertSetting == .enabled ? "Enabled" : "Disabled"
        status["soundSetting"] = settings.soundSetting == .enabled ? "Enabled" : "Disabled"
        status["badgeSetting"] = settings.badgeSetting == .enabled ? "Enabled" : "Disabled"
        status["notificationCenterSetting"] = settings.notificationCenterSetting == .enabled ? "Enabled" : "Disabled"
        status["lockScreenSetting"] = settings.lockScreenSetting == .enabled ? "Enabled" : "Disabled"
        status["carPlaySetting"] = settings.carPlaySetting == .enabled ? "Enabled" : "Disabled"
        status["criticalAlertSetting"] = settings.criticalAlertSetting == .enabled ? "Enabled" : "Disabled"

        // Push token
        let pushToken = PushwooshHelper.safeCall(nil) {
            Pushwoosh.sharedInstance().getPushToken()
        }
        if let pushToken = pushToken {
            status["pushToken"] = pushToken
        } else {
            status["pushToken"] = "Not registered"
        }

        // HWID
        let hwid = PushwooshHelper.safeCall("") {
            Pushwoosh.configure.getHWID()
        }
        status["hwid"] = hwid

        DispatchQueue.main.async {
            self.notificationStatus = status
            self.showNotificationStatus = true
        }
    }

    private func formatNotificationStatus(_ status: [AnyHashable: Any]) -> String {
        guard !status.isEmpty else {
            return "No status available"
        }

        var result = ""

        // Order keys for better readability
        let orderedKeys: [String] = [
            "authorizationStatus",
            "pushToken",
            "hwid",
            "alertSetting",
            "soundSetting",
            "badgeSetting",
            "notificationCenterSetting",
            "lockScreenSetting",
            "carPlaySetting",
            "criticalAlertSetting"
        ]

        for key in orderedKeys {
            if let value = status[key] {
                result += "\(key): \(value)\n"
            }
        }

        return result
    }
}

#Preview {
    RegistrationView()
}
