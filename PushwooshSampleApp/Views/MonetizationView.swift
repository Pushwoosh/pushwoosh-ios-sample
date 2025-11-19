//
//  MonetizationView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework

struct MonetizationView: View {
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
                            Text("MONETIZATION")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("In-App Purchases & Events")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // In-App Events Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundColor(.purple)
                                Text("In-App Events")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            Text("Use PWInAppManager to post custom events for in-app messaging triggers.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(4)

                            VStack(alignment: .leading, spacing: 8) {
                                EventExampleRow(
                                    name: "purchase_completed",
                                    description: "Track completed purchases",
                                    color: .green
                                )

                                EventExampleRow(
                                    name: "level_completed",
                                    description: "Track game progress",
                                    color: .blue
                                )

                                EventExampleRow(
                                    name: "subscription_started",
                                    description: "Track subscription events",
                                    color: .orange
                                )
                            }
                        }
                    }

                    // Purchase Tracking Info Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "cart.fill")
                                    .foregroundColor(.blue)
                                Text("Purchase Tracking")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            Text("Track StoreKit purchases to measure monetization and send targeted campaigns.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(4)

                            Divider()
                                .background(Color.white.opacity(0.2))

                            VStack(alignment: .leading, spacing: 8) {
                                InfoNoteRow(
                                    icon: "dollarsign.circle.fill",
                                    text: "sendPurchase: Track individual purchase events with price and currency",
                                    color: .green
                                )

                                InfoNoteRow(
                                    icon: "cart.badge.plus",
                                    text: "sendSKPaymentTransactions: Automatically track StoreKit transactions",
                                    color: .blue
                                )

                                InfoNoteRow(
                                    icon: "chart.bar.fill",
                                    text: "Track purchases to segment users by spending behavior",
                                    color: .purple
                                )
                            }
                        }
                    }

                    // Code Example Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .foregroundColor(.cyan)
                                Text("Code Examples")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                CodeExampleRow(
                                    title: "Post Event",
                                    code: "PWInAppManager.shared().postEvent(\"purchase_completed\")"
                                )

                                CodeExampleRow(
                                    title: "Post Event with Attributes",
                                    code: "PWInAppManager.shared().postEvent(\"purchase\", withAttributes: [\"amount\": 9.99])"
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

struct EventExampleRow: View {
    let name: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct CodeExampleRow: View {
    let title: String
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.cyan)

            Text(code)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                )
        }
    }
}

#Preview {
    MonetizationView()
}
