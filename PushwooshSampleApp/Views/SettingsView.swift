//
//  SettingsView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework

struct SettingsView: View {
    @State private var showPushnotificationAlert = true
    @State private var language: String = ""
    @State private var appCode: String = ""
    @State private var apiToken: String = ""
    @State private var showLanguageAlert = false
    @State private var currentLanguage: String = ""

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
                            Text("SETTINGS")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("SDK Configuration")
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

                    // Show Alert Toggle Card
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

                                    Text(showPushnotificationAlert ? "Enabled" : "Disabled")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(showPushnotificationAlert ? .green : .red.opacity(0.7))
                                }

                                Spacer()

                                Toggle("", isOn: $showPushnotificationAlert)
                                    .tint(.purple)
                                    .scaleEffect(0.9)
                                    .onChange(of: showPushnotificationAlert) { oldValue, newValue in
                                        PushwooshHelper.safeCall {
                                            Pushwoosh.configure.setShowPushnotificationAlert(newValue)
                                        }
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

                    // Language Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                Text("Language")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "LANGUAGE (e.g., 'en')", text: $language)

                            ModernButton(
                                title: "Set Language",
                                icon: "checkmark.circle.fill",
                                gradient: [.blue, .cyan]
                            ) {
                                PushwooshHelper.safeCall {
                                    Pushwoosh.configure.setLanguage(language)
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            ModernButton(
                                title: "Get Current Language",
                                icon: "arrow.down.circle.fill",
                                gradient: [.teal, .blue]
                            ) {
                                currentLanguage = PushwooshHelper.safeCall("") {
                                    Pushwoosh.configure.getLanguage()
                                }
                                showLanguageAlert = true
                            }
                            .alert(isPresented: $showLanguageAlert) {
                                Alert(
                                    title: Text("CURRENT LANGUAGE"),
                                    message: Text(currentLanguage.isEmpty ? "Not set" : currentLanguage),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                    }

                    // App Code Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "qrcode")
                                    .foregroundColor(.purple)
                                Text("App Code")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "APP CODE", text: $appCode)

                            ModernButton(
                                title: "Set App Code",
                                icon: "checkmark.circle.fill",
                                gradient: [.purple, .pink]
                            ) {
                                PushwooshHelper.safeCall {
                                    Pushwoosh.configure.setAppCode(appCode)
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Set your Pushwoosh application code. This is required for the SDK to communicate with your Pushwoosh app.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // API Token Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.orange)
                                Text("API Token")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "API TOKEN", text: $apiToken)

                            ModernButton(
                                title: "Set API Token",
                                icon: "checkmark.circle.fill",
                                gradient: [.orange, .red]
                            ) {
                                PushwooshHelper.safeCall {
                                    Pushwoosh.configure.setApiToken(apiToken)
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Set your Pushwoosh API token for additional authentication if required by your application.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Info Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Configuration Tips")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                InfoNoteRow(
                                    icon: "exclamationmark.triangle.fill",
                                    text: "Show Alerts: Controls whether notifications display as alerts when app is in foreground",
                                    color: .purple
                                )

                                InfoNoteRow(
                                    icon: "globe",
                                    text: "Language: ISO 639-1 language code (e.g., 'en', 'es', 'fr')",
                                    color: .blue
                                )

                                InfoNoteRow(
                                    icon: "qrcode",
                                    text: "App Code: Found in your Pushwoosh control panel settings",
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
        .onAppear {
            // Initialize toggle states based on current settings
            showPushnotificationAlert = PushwooshHelper.safeCall(true) {
                Pushwoosh.configure.getShowPushnotificationAlert()
            }
        }
    }
}

#Preview {
    SettingsView()
}
