//
//  LiveActivitiesView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework

struct LiveActivitiesView: View {
    @State private var activityId: String = ""
    @State private var pushToken: String = ""

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
                            Text("LIVE ACTIVITIES")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("iOS 16.1+ Dynamic Island")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "livephoto")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Start Live Activity Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.green)
                                Text("Start Live Activity")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "ACTIVITY ID", text: $activityId)

                            ModernTextField(placeholder: "PUSH TOKEN", text: $pushToken)

                            ModernButton(
                                title: "Start Activity",
                                icon: "play.fill",
                                gradient: [.green, .mint]
                            ) {
                                // Note: This is a placeholder
                                // Actual implementation would require ActivityKit configuration
                                // Pushwoosh.startLiveActivity(activityId, token: pushToken)
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Start a Live Activity with the specified ID and push token. Requires ActivityKit configuration in your app.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Stop Live Activity Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                    .foregroundColor(.red)
                                Text("Stop Live Activity")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "ACTIVITY ID", text: $activityId)

                            ModernButton(
                                title: "Stop Activity",
                                icon: "stop.fill",
                                gradient: [.red, .orange]
                            ) {
                                // Note: This is a placeholder
                                // Actual implementation would require ActivityKit configuration
                                // Pushwoosh.stopLiveActivity(activityId)
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Stop a running Live Activity by its ID. The activity will be removed from the Dynamic Island and Lock Screen.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Info Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("About Live Activities")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                InfoNoteRow(
                                    icon: "iphone.gen3",
                                    text: "Available on iOS 16.1+ with Dynamic Island support",
                                    color: .blue
                                )

                                InfoNoteRow(
                                    icon: "bell.badge.fill",
                                    text: "Show real-time updates in Dynamic Island and Lock Screen",
                                    color: .purple
                                )

                                InfoNoteRow(
                                    icon: "clock.fill",
                                    text: "Perfect for tracking deliveries, sports scores, ride-sharing, etc.",
                                    color: .green
                                )

                                InfoNoteRow(
                                    icon: "hammer.fill",
                                    text: "Requires ActivityKit widget configuration in your project",
                                    color: .orange
                                )
                            }
                        }
                    }

                    // Requirements Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checklist")
                                    .foregroundColor(.yellow)
                                Text("Setup Requirements")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                RequirementRow(
                                    number: 1,
                                    text: "Add ActivityKit widget target to your project",
                                    color: .blue
                                )

                                RequirementRow(
                                    number: 2,
                                    text: "Define Activity attributes and content state",
                                    color: .purple
                                )

                                RequirementRow(
                                    number: 3,
                                    text: "Configure push notification capability for Live Activities",
                                    color: .green
                                )

                                RequirementRow(
                                    number: 4,
                                    text: "Register activity token with Pushwoosh",
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
    }
}

struct RequirementRow: View {
    let number: Int
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(number)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LiveActivitiesView()
}
