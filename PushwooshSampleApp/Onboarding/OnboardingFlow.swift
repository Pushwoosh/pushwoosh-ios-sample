//
//  OnboardingFlow.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI
import PushwooshFramework

// Three-step first-run flow, mirroring the connect-then-sign-in pattern:
//   welcome -> connect (store access code) -> sign in.
// Connecting persists the code and re-points the SDK; signing in sets the
// Pushwoosh user id + email so campaigns can target this shopper.
struct OnboardingFlow: View {
    @AppStorage(PushMartStore.onboardedKey) private var onboarded = false
    @AppStorage(PushMartStore.appCodeKey)   private var appCode = ""
    @AppStorage(PushMartStore.userNameKey)  private var userName = ""
    @AppStorage(PushMartStore.userEmailKey) private var userEmail = ""

    private enum Step { case welcome, connect, signIn }
    @State private var step: Step = .welcome
    @State private var codeInput = ""
    @State private var codeError: String?
    @State private var nameInput = ""
    @State private var emailInput = ""

    var body: some View {
        ZStack {
            PushMartBackground()
            content
                .padding(.horizontal, 26)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
        }
        .dismissKeyboardOnTap()
        .onAppear {
            // Never pre-fill the bundled default code — show the XXXXX-XXXXX placeholder.
            // Only restore a code the shopper themselves entered on a previous run.
            if codeInput.isEmpty { codeInput = appCode }
        }
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .welcome: welcome
        case .connect: connect
        case .signIn:  signIn
        }
    }

    // MARK: Welcome

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            heroBadge
                .padding(.bottom, 30)
            PushMartWordmark(size: 40)
            Text("Shop what's next.")
                .font(PushMart.display(38))
                .foregroundStyle(PushMart.textPrimary)
                .padding(.top, 10)
            Text("Exclusive drops, live order tracking and deals picked just for you.")
                .font(PushMart.body(16))
                .foregroundStyle(PushMart.textSecondary)
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 14) {
                perk("bolt.fill", "Same-day delivery", "Track every order live on your Lock Screen")
                perk("sparkles", "Members-only drops", "Be first when limited items land")
                perk("tag.fill", "Personalized deals", "Offers tuned to what you love")
            }
            .padding(.top, 34)

            Spacer()
            PushMartButton(title: "Get started", icon: "arrow.right") {
                withAnimation { step = .connect }
            }
            .padding(.bottom, 14)
        }
        .padding(.vertical, 30)
    }

    private var heroBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(PushMart.brand)
                .frame(width: 92, height: 92)
                .shadow(color: PushMart.coral.opacity(0.5), radius: 24, y: 12)
            Image(systemName: "bag.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(PushMart.ink)
        }
    }

    private func perk(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(PushMart.coral)
                .frame(width: 46, height: 46)
                .background(Circle().fill(PushMart.coral.opacity(0.14)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                Text(subtitle).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: Connect (store access code)

    private var connect: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(index: 1, title: "Connect your store",
                       subtitle: "Enter your store access code to load your catalog and offers.")
            PushMartField(placeholder: "XXXXX-XXXXX", text: $codeInput, icon: "qrcode")
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .onChange(of: codeInput) { _, newValue in
                    let masked = newValue.maskedAsAppCode
                    if masked != codeInput { codeInput = masked }
                    codeError = nil
                }
                .padding(.top, 26)

            if let codeError {
                Text(codeError)
                    .font(PushMart.body(12.5))
                    .foregroundStyle(PushMart.coral)
                    .padding(.top, 8)
            }

            HStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
                Text("Your code is stored on this device only.")
                    .font(PushMart.body(12.5))
            }
            .foregroundStyle(PushMart.textTertiary)
            .padding(.top, 12)

            Spacer()
            PushMartButton(title: "Continue", icon: "arrow.right") { connectStore() }
                .sdkNote("Pushwoosh.configure.setAppCode(_:)",
                         "Points the SDK at your store's Pushwoosh application when you connect.",
                         calls: [
                            .init(code: "setAppCode(code)",
                                  note: "Re-points the SDK to the entered store access code (validated as XXXXX-XXXXX)."),
                         ])
            PushMartButton(title: "Back", style: .ghost) { withAnimation { step = .welcome } }
                .padding(.top, 6)
                .padding(.bottom, 14)
        }
        .padding(.top, 40)
    }

    private func connectStore() {
        let code = codeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.isValidAppCode else {
            withAnimation { codeError = "Enter your access code in the format XXXXX-XXXXX." }
            return
        }
        codeError = nil
        appCode = code
        PushwooshHelper.safeCall { Pushwoosh.configure.setAppCode(code) }
        ServerRouting.apply()
        withAnimation { step = .signIn }
    }

    // MARK: Sign in

    private var signIn: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(index: 2, title: "Create your account",
                       subtitle: "Sign in so your cart, orders and rewards follow you everywhere.")
            VStack(spacing: 12) {
                PushMartField(placeholder: "YOUR NAME", text: $nameInput, icon: "person.fill")
                    .textContentType(.name)
                PushMartField(placeholder: "EMAIL", text: $emailInput, icon: "envelope.fill")
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.top, 24)

            Spacer()
            PushMartButton(title: "Continue", icon: "checkmark") { signInAndFinish() }
                .sdkNote("Pushwoosh.configure.setEmail(_:) · setUserId(_:)",
                         "Tells Pushwoosh who this shopper is, so orders and offers follow them across devices.",
                         calls: [
                            .init(code: "setEmail(email)",
                                  note: "Attaches the entered email so campaigns can reach this shopper by email."),
                            .init(code: "setUserId(email)",
                                  note: "Uses the email as the user ID so all activity links to one profile."),
                         ])
            PushMartButton(title: "Continue as guest", style: .ghost) { finish() }
                .padding(.top, 6)
                .padding(.bottom, 14)
        }
        .padding(.top, 40)
    }

    private func signInAndFinish() {
        let email = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        userName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        userEmail = email
        if !email.isEmpty {
            PushwooshHelper.safeCall { Pushwoosh.configure.setEmail(email) }
            PushwooshHelper.safeCall { Pushwoosh.configure.setUserId(email) }
        }
        finish()
    }

    private func finish() {
        withAnimation { onboarded = true }
    }

    // MARK: Shared

    private func stepHeader(index: Int, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(1...2, id: \.self) { i in
                    Capsule()
                        .fill(i <= index ? AnyShapeStyle(PushMart.brandHorizontal) : AnyShapeStyle(PushMart.surfaceHi))
                        .frame(width: i == index ? 26 : 18, height: 5)
                }
            }
            Text(title)
                .font(PushMart.display(30))
                .foregroundStyle(PushMart.textPrimary)
                .padding(.top, 8)
            Text(subtitle)
                .font(PushMart.body(15))
                .foregroundStyle(PushMart.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnboardingFlow()
}
