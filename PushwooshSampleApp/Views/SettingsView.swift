//
//  SettingsView.swift
//  PushMart
//

import SwiftUI
import PushwooshFramework

// App settings. Foreground-alert toggle, language (+ inline current value),
// store access code and API token. Every setter fires the shared success overlay;
// getLanguage is shown inline rather than in an alert.
struct SettingsView: View {
    @State private var showPushnotificationAlert = true
    @State private var language = ""
    @State private var appCode = ""
    @State private var apiToken = ""
    @State private var currentLanguage = ""

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    alertsCard
                        .sdkNote("Pushwoosh.configure.setShowPushnotificationAlert(_:)",
                                 "Turns the in-app banner for incoming pushes on or off while you're using PushMart.",
                                 docs: "On appear the toggle is initialised from getShowPushnotificationAlert() so it reflects the value the SDK already has stored.",
                                 calls: [
                                    .init(code: "setShowPushnotificationAlert(true)",
                                          note: "Toggle on - show the foreground alert banner when a push arrives while the app is open."),
                                    .init(code: "setShowPushnotificationAlert(false)",
                                          note: "Toggle off - suppress the foreground alert banner for incoming pushes."),
                                    .init(code: "getShowPushnotificationAlert()",
                                          note: "Read on appear to sync the toggle with the SDK's stored setting."),
                                 ])
                    languageCard
                        .sdkNote("Pushwoosh.configure.setLanguage(_:)",
                                 "Sets the language Pushwoosh uses for targeting and localized messages.",
                                 calls: [
                                    .init(code: "setLanguage(lang)",
                                          note: "Set language - applies the entered code (e.g. “en”) as the device language."),
                                    .init(code: "getLanguage()",
                                          note: "Current - reads the language currently stored by the SDK and shows it inline."),
                                 ])
                    appCodeCard
                        .sdkNote("Pushwoosh.configure.setAppCode(_:)",
                                 "Points the SDK at a different Pushwoosh application (access) code at runtime.",
                                 calls: [
                                    .init(code: "setAppCode(code)",
                                          note: "Set access code - re-points the SDK to the entered store access code."),
                                 ])
                    apiTokenCard
                        .sdkNote("Pushwoosh.configure.setApiToken(_:)",
                                 "Sets the API token the SDK uses to authenticate requests to Pushwoosh.",
                                 calls: [
                                    .init(code: "setApiToken(token)",
                                          note: "Set API token - stores the pasted token for the SDK to authenticate with."),
                                    .init(code: "getApiToken()",
                                          note: "Current - reads the API token currently stored by the SDK and fills the field."),
                                 ])
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .onAppear {
            showPushnotificationAlert = PushwooshHelper.safeCall(true) {
                Pushwoosh.configure.getShowPushnotificationAlert()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("App settings").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("Language, alerts & access").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(.top, 4)
    }

    private var alertsCard: some View {
        PushMartCard {
            HStack(spacing: 14) {
                Circle().fill(PushMart.coral.opacity(0.16)).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "app.badge.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(PushMart.coral))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show alerts in-app").font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                    Text("Banner while you're using PushMart").font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $showPushnotificationAlert)
                    .labelsHidden().tint(PushMart.coral)
                    .onChange(of: showPushnotificationAlert) { _, newValue in
                        PushwooshHelper.safeCall {
                            Pushwoosh.configure.setShowPushnotificationAlert(newValue)
                        }
                        PushMartResult.shared.success(newValue ? "Alerts on" : "Alerts off")
                    }
            }
        }
    }

    private var languageCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Language").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    Button {
                        currentLanguage = PushwooshHelper.safeCall("") { Pushwoosh.configure.getLanguage() }
                    } label: {
                        Text("Current").font(PushMart.label(13)).foregroundStyle(PushMart.coral)
                    }
                }
                if !currentLanguage.isEmpty {
                    Text("Currently: \(currentLanguage)")
                        .font(.system(size: 13, design: .monospaced)).foregroundStyle(PushMart.textSecondary)
                }
                PushMartField(placeholder: "LANGUAGE CODE (e.g. en)", text: $language, icon: "globe")
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                PushMartButton(title: "Set language", icon: "checkmark") {
                    let lang = language.trimmingCharacters(in: .whitespaces)
                    guard !lang.isEmpty else {
                        PushMartResult.shared.fail("No language set", "Enter a language code like “en”.")
                        return
                    }
                    PushwooshHelper.safeCall { Pushwoosh.configure.setLanguage(lang) }
                    currentLanguage = lang
                    PushMartResult.shared.success("Language set", lang)
                }
            }
        }
    }

    private var appCodeCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Store access code").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                PushMartField(placeholder: "XXXXX-XXXXX", text: $appCode, icon: "qrcode")
                    .textInputAutocapitalization(.characters).autocorrectionDisabled()
                    .onChange(of: appCode) { _, newValue in
                        let masked = newValue.maskedAsAppCode
                        if masked != appCode { appCode = masked }
                    }
                PushMartButton(title: "Set access code", icon: "checkmark") {
                    let code = appCode.trimmingCharacters(in: .whitespaces).uppercased()
                    guard code.isValidAppCode else {
                        PushMartResult.shared.fail("Invalid code", "Use the format XXXXX-XXXXX.")
                        return
                    }
                    PushwooshHelper.safeCall { Pushwoosh.configure.setAppCode(code) }
                    PushMartResult.shared.success("Access code set", code)
                }
            }
        }
    }

    private var apiTokenCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("API token").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    Button {
                        apiToken = PushwooshHelper.safeCall(nil) { Pushwoosh.configure.getApiToken() } ?? ""
                    } label: {
                        Text("Current").font(PushMart.label(13)).foregroundStyle(PushMart.coral)
                    }
                }
                PushMartField(placeholder: "API TOKEN", text: $apiToken, icon: "key.fill")
                    .autocorrectionDisabled()
                PushMartButton(title: "Set API token", icon: "checkmark") {
                    let token = apiToken.trimmingCharacters(in: .whitespaces)
                    guard !token.isEmpty else {
                        PushMartResult.shared.fail("No API token set", "Paste your API token first.")
                        return
                    }
                    PushwooshHelper.safeCall { Pushwoosh.configure.setApiToken(token) }
                    PushMartResult.shared.success("API token set")
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
