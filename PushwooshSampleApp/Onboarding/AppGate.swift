//
//  AppGate.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI
import PushwooshFramework

// Persisted onboarding / identity store. The app code the shopper connects with
// is remembered here and applied through setAppCode so the SDK talks to the right
// project. There is no bundled working code any more — it is entered during
// onboarding (PushOn-style auth), so infoPlistAppCode is normally empty.
enum PushMartStore {
    static let onboardedKey = "nuvo.onboarded"
    static let appCodeKey   = "nuvo.appCode"
    static let userNameKey  = "nuvo.userName"
    static let userEmailKey = "nuvo.userEmail"

    static var infoPlistAppCode: String {
        Bundle.main.object(forInfoDictionaryKey: "Pushwoosh_APPID") as? String ?? ""
    }

    static var appCode: String {
        let stored = UserDefaults.standard.string(forKey: appCodeKey)
        return (stored?.isEmpty == false) ? stored! : infoPlistAppCode
    }
}

// Two-region deployment, written the way a customer writes it: the shopper picks the country they
// shop in, and each country is a separate Pushwoosh application living behind its own API endpoint.
// The pair travels in one call, so the device is never registered into one region's application at
// another region's host. A real deployment would carry that region's own hosts here; the demo points
// at the bundled mock servers so a switch can be followed end to end.
enum StoreRegion: String, CaseIterable {
    case unitedStates
    case honduras

    static let storageKey = "nuvo.region"

    var title: String {
        switch self {
        case .unitedStates: return "United States"
        case .honduras:     return "Honduras"
        }
    }

    var flag: String {
        switch self {
        case .unitedStates: return "🇺🇸"
        case .honduras:     return "🇭🇳"
        }
    }

    var appCode: String {
        switch self {
        case .unitedStates: return "USAAA-00000"
        case .honduras:     return "HNDRS-11111"
        }
    }

    var baseUrl: String {
        switch self {
        case .unitedStates: return "http://127.0.0.1:9595/json/1.3/"
        case .honduras:     return "http://127.0.0.1:9596/json/1.3/"
        }
    }

    // nil until the shopper has chosen, so a fresh install keeps using the onboarding app code.
    static var stored: StoreRegion? {
        guard let raw = UserDefaults.standard.string(forKey: storageKey) else { return nil }
        return StoreRegion(rawValue: raw)
    }

    // Safe to call on every launch: repeating the pair the SDK already holds is a no-op.
    func apply() {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
        Pushwoosh.configure.setAppCode(appCode, baseUrl: baseUrl)
    }
}

// App code validation, mirroring PushOn's login check (non-empty + the XXXXX-XXXXX shape;
// PushOn masks input to [_____]-[_____] and requires length 11). The alphanumeric groups
// also exclude the dotted ids the SDK rejects (SDK-814).
extension String {
    var isValidAppCode: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: #"^[A-Za-z0-9]{5}-[A-Za-z0-9]{5}$"#, options: .regularExpression) != nil
    }

    // Formats free input to the Pushwoosh XXXXX-XXXXX shape: uppercased alphanumerics,
    // a hyphen after the 5th char, capped at 10 chars. Drives the app-code fields' input mask
    // (PushOn uses an InputMask [_____]-[_____] field; this is the SwiftUI-native equivalent).
    var maskedAsAppCode: String {
        let alnum = uppercased().filter { $0.isLetter || $0.isNumber }
        let clipped = String(alnum.prefix(10))
        guard clipped.count > 5 else { return clipped }
        let cut = clipped.index(clipped.startIndex, offsetBy: 5)
        return String(clipped[..<cut]) + "-" + String(clipped[cut...])
    }
}

// Root of the app: shows onboarding until the shopper has connected + signed in,
// then hands off to the main shopping experience.
struct AppGate: View {
    @AppStorage(PushMartStore.onboardedKey) private var onboarded = false

    var body: some View {
        Group {
            if onboarded {
                ContentView()
            } else {
                OnboardingFlow()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: onboarded)
    }
}

// MARK: - Account / app-code switching (runtime, no Info.plist)
//
// The app code is set programmatically via Pushwoosh.configure.setAppCode — the same
// PWPreferences path the SDK uses, so Info.plist Pushwoosh_APPID is only a first-run
// fallback. Switching account re-points the SDK at another Pushwoosh app at runtime,
// mirroring PushOn's flow on the modern configure API: unregister from the current app →
// switch app code → set identity → register with the new app
// → resync the inbox.
enum AccountManager {

    /// Connect to a different Pushwoosh app (account) at runtime.
    static func apply(appCode: String, name: String, email: String) {
        let code = appCode.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.isValidAppCode else {
            PushMartResult.shared.fail("Invalid app code", "Use the format XXXXX-XXXXX.")
            return
        }
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        let cleanEmail = email.trimmingCharacters(in: .whitespaces)

        Task {
            // 1. Unregister the device from the CURRENT app before switching.
            await PushwooshHelper.safeCall { try? await Pushwoosh.configure.unregisterForPushNotifications() }

            await MainActor.run {
                // 2. Switch the app code — the SDK resets per-app state when it changes.
                PushwooshHelper.safeCall { Pushwoosh.configure.setAppCode(code) }
                // 3. Persist the code the shopper connected with.
                UserDefaults.standard.set(code, forKey: PushMartStore.appCodeKey)
                // 4. Identity for the new account.
                if !cleanEmail.isEmpty {
                    PushwooshHelper.safeCall { Pushwoosh.configure.setEmail(cleanEmail) }
                    PushwooshHelper.safeCall { Pushwoosh.configure.setUserId(cleanEmail) }
                }
                UserDefaults.standard.set(cleanName, forKey: PushMartStore.userNameKey)
                UserDefaults.standard.set(cleanEmail, forKey: PushMartStore.userEmailKey)
                // 5. Register the device with the NEW app.
                PushwooshHelper.safeCall { Pushwoosh.configure.registerForPushNotifications { _, _ in } }
                PushMartResult.shared.success("Account switched", "Connected to app \(code).")
            }

            // 6. Resync the inbox for the new account.
            await PushwooshHelper.safeCall { _ = await PWInbox.resyncInboxForNewUserId() }
        }
    }

    /// Log out of the current account: unregister, clear identity, return to onboarding.
    static func logout() {
        Task {
            await PushwooshHelper.safeCall { try? await Pushwoosh.configure.unregisterForPushNotifications() }
            await MainActor.run {
                UserDefaults.standard.removeObject(forKey: PushMartStore.userNameKey)
                UserDefaults.standard.removeObject(forKey: PushMartStore.userEmailKey)
                UserDefaults.standard.set(false, forKey: PushMartStore.onboardedKey)
            }
        }
    }
}

// Sheet to switch to a different Pushwoosh app / account at runtime.
struct SwitchAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appCode = ""
    @State private var name = ""
    @State private var email = ""
    @State private var region = StoreRegion.stored

    var body: some View {
        ZStack {
            PushMart.ink.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Switch account").font(PushMart.display(28)).foregroundStyle(PushMart.textPrimary)
                        Text("Connect to a different Pushwoosh app. This unregisters the current device, switches the app code, then registers again.")
                            .font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)

                    regionSection

                    Text("Or connect to a project by app code")
                        .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)

                    PushMartField(placeholder: "App code (XXXXX-XXXXX)", text: $appCode, icon: "qrcode")
                    PushMartField(placeholder: "Name (optional)", text: $name, icon: "person")
                    PushMartField(placeholder: "Email (optional)", text: $email, icon: "envelope")

                    PushMartButton(title: "Switch account", icon: "arrow.left.arrow.right") {
                        AccountManager.apply(appCode: appCode, name: name, email: email)
                        dismiss()
                    }
                    .disabled(appCode.trimmingCharacters(in: .whitespaces).isEmpty)
                    .sdkNote(
                        "Pushwoosh.configure.setAppCode / register / unregister",
                        "Switching re-points the SDK at another Pushwoosh app at runtime.",
                        docs: "The app code is stored in UserDefaults and applied via setAppCode (the same PWPreferences path the SDK uses), so Info.plist Pushwoosh_APPID is only a first-run fallback.",
                        calls: [
                            SDKCallItem(code: "unregisterForPushNotifications()", note: "Unregisters the device from the current app."),
                            SDKCallItem(code: "setAppCode(newCode)", note: "Switches to the new app; the SDK resets per-app state."),
                            SDKCallItem(code: "setEmail(email) / setUserId(email)", note: "Sets the identity for the new account."),
                            SDKCallItem(code: "registerForPushNotifications { }", note: "Registers the device with the new app."),
                            SDKCallItem(code: "PWInbox.resyncInboxForNewUserId()", note: "Refreshes the inbox for the new account.")
                        ]
                    )

                    Text("Tip: the current app code is prefilled. Enter another to connect to a different project.")
                        .font(PushMart.body(12)).foregroundStyle(PushMart.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
        }
        .onAppear {
            appCode = PushwooshHelper.safeCall(nil) { Pushwoosh.configure.getApplicationCode() } ?? ""
            region = StoreRegion.stored
        }
        .dismissKeyboardOnTap()
        .presentationDragIndicator(.visible)
    }

    private var regionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Region").font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
            Text("Where do you shop? Each country is served by its own Pushwoosh application, so switching moves the device to that country's application.")
                .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(StoreRegion.allCases, id: \.rawValue) { candidate in
                PushMartButton(title: "\(candidate.flag)  \(candidate.title)",
                               icon: region == candidate ? "checkmark.circle.fill" : "circle",
                               style: .secondary) {
                    candidate.apply()
                    region = candidate
                    PushMartResult.shared.success("Region: \(candidate.title)")
                    dismiss()
                }
            }
            .sdkNote(
                "Pushwoosh.configure.setAppCode(_:baseUrl:)",
                "Moves the application code and its API endpoint as one unit.",
                docs: "Called once per region choice and again on every launch with the stored region; repeating the same pair is a no-op, so it is safe to apply at startup.",
                calls: [
                    SDKCallItem(code: "setAppCode(\"HNDRS-11111\", baseUrl: \"https://…/json/1.3/\")",
                                note: "Region switch - the device is unregistered from the previous region's application and registered in the new one."),
                    SDKCallItem(code: "setAppCode(code, baseUrl: nil)",
                                note: "Default endpoint - falls back to Info.plist Pushwoosh_BASEURL, else https://<appCode>.api.pushwoosh.com/json/1.3/.")
                ]
            )
        }
    }
}

#Preview {
    AppGate()
}
