//
//  Settings.swift
//  newdemo
//
//  Created by Andrew Kis on 12.4.24..
//

import Foundation
import SwiftUI
import PushwooshFramework

struct Settings: View {
    @State private var pushNotificationEnabled = false
    @State private var notificationAlertEnabled = true
    @State private var communicationEnabled = true

    var body: some View {
        ZStack {
            // Background gradient matching Actions
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
                            Text("SETTINGS")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Configure Pushwoosh")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Push Notifications Card
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
                                        if newValue {
                                            Pushwoosh.configure.registerForPushNotifications()
                                        } else {
                                            Task {
                                                try? await Pushwoosh.configure.unregisterForPushNotifications()
                                            }
                                        }
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

                    // Alerts Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Show Alerts")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text(notificationAlertEnabled ? "Enabled" : "Disabled")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(notificationAlertEnabled ? .green : .red.opacity(0.7))
                                }

                                Spacer()

                                Toggle("", isOn: $notificationAlertEnabled)
                                    .tint(.purple)
                                    .scaleEffect(0.9)
                                    .onChange(of: notificationAlertEnabled) { oldValue, newValue in
                                        Pushwoosh.configure.setShowPushnotificationAlert(newValue)
                                    }
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Display alert dialogs when push notifications are received while the app is active.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Communication Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "wifi")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Server Communication")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text(communicationEnabled ? "Active" : "Paused")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(communicationEnabled ? .green : .red.opacity(0.7))
                                }

                                Spacer()

                                Toggle("", isOn: $communicationEnabled)
                                    .tint(.green)
                                    .scaleEffect(0.9)
                                    .onChange(of: communicationEnabled) { oldValue, newValue in
                                        if newValue {
                                            Pushwoosh.configure.startServerCommunication()
                                        } else {
                                            Pushwoosh.configure.stopServerCommunication()
                                        }
                                    }
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Control communication with Pushwoosh servers. When disabled, no data will be sent or received.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Info Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.cyan)
                                    .font(.system(size: 20))
                                Text("About")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(spacing: 12) {
                                SettingsInfoRow(
                                    icon: "app.badge.fill",
                                    label: "Version",
                                    value: "1.0.0",
                                    color: .blue
                                )

                                SettingsInfoRow(
                                    icon: "building.2.fill",
                                    label: "Framework",
                                    value: "Pushwoosh SDK",
                                    color: .purple
                                )

                                SettingsInfoRow(
                                    icon: "swift",
                                    label: "Platform",
                                    value: "iOS / SwiftUI",
                                    color: .orange
                                )
                            }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            // Initialize toggle states based on current settings
            notificationAlertEnabled = Pushwoosh.configure.getShowPushnotificationAlert()
        }
    }
}

// MARK: - Settings Components

struct SettingsInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    Settings()
}
