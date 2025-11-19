//
//  NotificationsView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework

struct NotificationsView: View {
    @State private var notificationTitle: String = ""
    @State private var notificationBody: String = ""

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
                            Text("NOTIFICATIONS")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Local & Push Notifications")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "app.badge.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Send Local Notification Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.blue)
                                Text("Local Notification")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "TITLE", text: $notificationTitle)

                            ModernTextField(placeholder: "BODY", text: $notificationBody)

                            ModernButton(
                                title: "Send Local Notification",
                                icon: "bell.badge.fill",
                                gradient: [.blue, .cyan]
                            ) {
                                let title = notificationTitle.isEmpty ? "Hello" : notificationTitle
                                let body = notificationBody.isEmpty ? "Pushwoosh" : notificationBody
                                Notifications.shared.showLocalNotification(title: title, body: body)
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Send a local notification to test notification display and handling. Does not require server connection.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Notification Actions Card
                    ModernCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "bolt.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Notification Actions")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernButton(
                                title: "Send Test Notification",
                                icon: "bell.badge.fill",
                                gradient: [.indigo, .purple]
                            ) {
                                Notifications.shared.showLocalNotification(title: "Test", body: "This is a test notification")
                            }

                            ModernButton(
                                title: "Clear All Notifications",
                                icon: "bell.slash.fill",
                                gradient: [.gray, .secondary]
                            ) {
                                PushNotificationManager.clearNotificationCenter()
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Quick actions for testing and managing notifications.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Notification Features Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Notification Features")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                FeatureRow(
                                    icon: "bell.badge.fill",
                                    title: "Rich Notifications",
                                    description: "Images, videos, and custom actions",
                                    color: .blue
                                )

                                FeatureRow(
                                    icon: "map.fill",
                                    title: "Geolocation",
                                    description: "Location-based push notifications",
                                    color: .green
                                )

                                FeatureRow(
                                    icon: "clock.fill",
                                    title: "Scheduled Push",
                                    description: "Send notifications at specific times",
                                    color: .orange
                                )

                                FeatureRow(
                                    icon: "person.3.fill",
                                    title: "Segmentation",
                                    description: "Target specific user groups",
                                    color: .purple
                                )
                            }
                        }
                    }

                    // Info Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("About Notifications")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                InfoNoteRow(
                                    icon: "bell.fill",
                                    text: "Local Notifications: Scheduled locally by the app without server involvement",
                                    color: .blue
                                )

                                InfoNoteRow(
                                    icon: "antenna.radiowaves.left.and.right",
                                    text: "Push Notifications: Sent from Pushwoosh servers via APNs",
                                    color: .green
                                )

                                InfoNoteRow(
                                    icon: "hand.raised.fill",
                                    text: "User must grant notification permissions for the app",
                                    color: .orange
                                )

                                InfoNoteRow(
                                    icon: "app.badge.fill",
                                    text: "Notifications can update app badge, play sounds, and show alerts",
                                    color: .purple
                                )
                            }
                        }
                    }

                    // Delegate Info Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundColor(.pink)
                                Text("Notification Handling")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            Text("Use PWMessagingDelegate to handle notification events:")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(4)

                            VStack(alignment: .leading, spacing: 8) {
                                DelegateMethodRow(
                                    method: "onPushReceived",
                                    description: "Called when notification is received"
                                )

                                DelegateMethodRow(
                                    method: "onPushAccepted",
                                    description: "Called when user taps notification"
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
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct DelegateMethodRow: View {
    let method: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.pink)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(method)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    NotificationsView()
}
