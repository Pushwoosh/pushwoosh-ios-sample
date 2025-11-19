//
//  DeviceInfoView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework

struct DeviceInfoView: View {
    @State private var showPushToken = false
    @State private var showHwid = false
    @State private var showAppCode = false

    var body: some View {
        let pushToken = PushwooshHelper.safeCall(nil) {
            Pushwoosh.configure.getPushToken()
        }
        let hwid = PushwooshHelper.safeCall("") {
            Pushwoosh.configure.getHWID()
        }
        let appCode = PushwooshHelper.safeCall(nil) {
            Pushwoosh.configure.getApplicationCode()
        }

        return ZStack {
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
                            Text("DEVICE INFO")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Device Details")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "iphone")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Info Cards
                    ModernCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("Device Information")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            InfoButton(
                                title: "Push Token",
                                icon: "key.fill",
                                color: .cyan
                            ) {
                                showPushToken = true
                            }
                            .alert(isPresented: $showPushToken) {
                                Alert(
                                    title: Text("PUSH TOKEN"),
                                    message: Text(pushToken ?? "Push Token doesn't exist"),
                                    dismissButton: .default(Text("OK"))
                                )
                            }

                            InfoButton(
                                title: "HWID",
                                icon: "desktopcomputer",
                                color: .blue
                            ) {
                                showHwid = true
                            }
                            .alert(isPresented: $showHwid) {
                                Alert(
                                    title: Text("HWID"),
                                    message: Text(hwid),
                                    dismissButton: .default(Text("OK"))
                                )
                            }

                            InfoButton(
                                title: "App Code",
                                icon: "qrcode",
                                color: .purple
                            ) {
                                showAppCode = true
                            }
                            .alert(isPresented: $showAppCode) {
                                Alert(
                                    title: Text("APPLICATION CODE"),
                                    message: Text(appCode ?? "Not set"),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                    }

                    // Device Details Display Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.green)
                                Text("Quick View")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(spacing: 12) {
                                DeviceInfoRow(
                                    icon: "key.fill",
                                    label: "Push Token",
                                    value: pushToken != nil ? "Set" : "Not Available",
                                    valueColor: pushToken != nil ? .green : .red,
                                    color: .cyan
                                )

                                DeviceInfoRow(
                                    icon: "desktopcomputer",
                                    label: "HWID",
                                    value: hwid.isEmpty ? "Not Available" : "Set",
                                    valueColor: hwid.isEmpty ? .red : .green,
                                    color: .blue
                                )

                                DeviceInfoRow(
                                    icon: "qrcode",
                                    label: "App Code",
                                    value: appCode != nil ? "Set" : "Not Set",
                                    valueColor: appCode != nil ? .green : .red,
                                    color: .purple
                                )
                            }
                        }
                    }

                    // Info Note Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("About Device Info")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                InfoNoteRow(
                                    icon: "key.fill",
                                    text: "Push Token: APNs token for sending notifications to this device",
                                    color: .cyan
                                )

                                InfoNoteRow(
                                    icon: "desktopcomputer",
                                    text: "HWID: Unique hardware identifier for this device in Pushwoosh",
                                    color: .blue
                                )

                                InfoNoteRow(
                                    icon: "qrcode",
                                    text: "App Code: Your Pushwoosh application identifier",
                                    color: .purple
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

struct DeviceInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let valueColor: Color
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
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct InfoNoteRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DeviceInfoView()
}
