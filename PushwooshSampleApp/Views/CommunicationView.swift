//
//  CommunicationView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework

struct CommunicationView: View {
    @State private var communicationEnabled = true
    @State private var showStatusAlert = false

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
                            Text("COMMUNICATION")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Server Connection")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Server Communication Toggle Card
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
                                            PushwooshHelper.safeCall {
                                                Pushwoosh.configure.startServerCommunication()
                                            }
                                        } else {
                                            PushwooshHelper.safeCall {
                                                Pushwoosh.configure.stopServerCommunication()
                                            }
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

                    // Manual Control Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "手.fill")
                                    .foregroundColor(.blue)
                                Text("Manual Control")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernButton(
                                title: "Start Communication",
                                icon: "play.circle.fill",
                                gradient: [.green, .mint]
                            ) {
                                PushwooshHelper.safeCall {
                                    Pushwoosh.configure.startServerCommunication()
                                }
                                communicationEnabled = true
                            }

                            ModernButton(
                                title: "Stop Communication",
                                icon: "stop.circle.fill",
                                gradient: [.red, .orange]
                            ) {
                                PushwooshHelper.safeCall {
                                    Pushwoosh.configure.stopServerCommunication()
                                }
                                communicationEnabled = false
                            }
                        }
                    }

                    // Status Check Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("Connection Status")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernButton(
                                title: "Check Communication Status",
                                icon: "checklist",
                                gradient: [.cyan, .blue]
                            ) {
                                communicationEnabled = PushwooshHelper.safeCall(false) {
                                    Pushwoosh.configure.isServerCommunicationAllowed()
                                }
                                showStatusAlert = true
                            }
                            .alert(isPresented: $showStatusAlert) {
                                Alert(
                                    title: Text("COMMUNICATION STATUS"),
                                    message: Text(communicationEnabled ? "Server communication is ACTIVE" : "Server communication is PAUSED"),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                    }

                    // Info Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("About Server Communication")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                InfoNoteRow(
                                    icon: "wifi",
                                    text: "When active, the SDK sends device data and receives push notifications",
                                    color: .green
                                )

                                InfoNoteRow(
                                    icon: "wifi.slash",
                                    text: "When paused, no network requests are made to Pushwoosh servers",
                                    color: .red
                                )

                                InfoNoteRow(
                                    icon: "exclamationmark.triangle.fill",
                                    text: "Pausing communication will prevent receiving push notifications",
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
            // Initialize toggle state based on current status
            communicationEnabled = PushwooshHelper.safeCall(false) {
                Pushwoosh.configure.isServerCommunicationAllowed()
            }
        }
    }
}

#Preview {
    CommunicationView()
}
