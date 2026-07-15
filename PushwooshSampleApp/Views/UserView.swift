//
//  UserView.swift
//  PushMart
//

import SwiftUI
import PushwooshFramework

// Account screen. The signature is a PushMart membership card: the shopper's
// identity lives on the card itself. `getUserId()` is played as a "sync" — tap
// the card and it pulls the current member id from the SDK with a shine sweep,
// instead of hiding the value behind an alert. The quiet form below sets the
// user id / email (setUserId / setEmail) and re-syncs the card.
struct UserView: View {
    @AppStorage(PushMartStore.userEmailKey) private var storedEmail = ""

    @State private var userId = ""
    @State private var email = ""
    @State private var memberId = ""
    @State private var shine = false
    @State private var syncedNote = "Tap your card to sync"
    @State private var justSaved = false
    @State private var phone = ""
    @State private var whatsapp = ""
    @State private var emails = ""
    @State private var oldUserId = ""
    @State private var doMerge = true

    var body: some View {
        ZStack {
            PushMartBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    memberCard
                    syncRow
                    detailsForm
                    identityAdvancedCard
                    channelsCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .onAppear {
            if email.isEmpty { email = storedEmail }
            sync(animated: false)
            if userId.isEmpty { userId = memberId }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Account").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("Your membership & identity")
                .font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(.top, 4)
    }

    // MARK: Signature — membership card

    private var memberCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PushMart.brand)

            // faint concentric guilloché-style rings for a "real card" texture
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                            .frame(width: geo.size.width * (0.7 + CGFloat(i) * 0.28))
                            .offset(x: geo.size.width * 0.34, y: -geo.size.height * 0.2)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PUSHMART").font(.system(size: 15, weight: .black, design: .rounded))
                            .tracking(3).foregroundStyle(PushMart.ink)
                        Text("MEMBER").font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(2.5).foregroundStyle(PushMart.ink.opacity(0.55))
                    }
                    Spacer()
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(PushMart.ink.opacity(0.7))
                }

                // chip
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LinearGradient(colors: [Color(rgb: 0xFFE7A8), Color(rgb: 0xE8B75C)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 33)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PushMart.ink.opacity(0.15), lineWidth: 1))
                    .padding(.top, 18)

                Text(memberId.isEmpty ? "—— —— ——" : memberId)
                    .font(.system(size: 21, weight: .bold, design: .monospaced))
                    .foregroundStyle(memberId.isEmpty ? PushMart.ink.opacity(0.45) : PushMart.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.top, 14)

                Spacer(minLength: 8)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MEMBER").font(.system(size: 8, weight: .heavy, design: .rounded))
                            .tracking(1.5).foregroundStyle(PushMart.ink.opacity(0.55))
                        Text(cardEmail).font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(PushMart.ink.opacity(0.85)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    Spacer()
                    Image(systemName: "bag.fill").font(.system(size: 20, weight: .bold))
                        .foregroundStyle(PushMart.ink.opacity(0.85))
                }
            }
            .padding(20)

            // shine sweep (fires on sync)
            GeometryReader { geo in
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, .white.opacity(0.55), .clear],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: geo.size.width * 0.35)
                    .rotationEffect(.degrees(22))
                    .offset(x: shine ? geo.size.width * 1.1 : -geo.size.width * 0.6)
                    .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)
        }
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: PushMart.coral.opacity(0.35), radius: 24, x: 0, y: 14)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture { sync(animated: true) }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("memberCard")
    }

    private var cardEmail: String {
        email.isEmpty ? (storedEmail.isEmpty ? "not set" : storedEmail) : email
    }

    // MARK: Sync row (getUserId)

    private var syncRow: some View {
        HStack(spacing: 8) {
            Image(systemName: justSaved ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(justSaved ? PushMart.success : PushMart.textTertiary)
            Text(syncedNote).font(PushMart.body(13)).foregroundStyle(PushMart.textTertiary)
            Spacer()
            Button { sync(animated: true) } label: {
                Text("Sync now").font(PushMart.label(13)).foregroundStyle(PushMart.coral)
            }
            .accessibilityIdentifier("syncMemberButton")
        }
        .sdkNote("Pushwoosh.configure.getUserId()",
                 "Reads the member ID Pushwoosh currently has for this device and shows it on the card.",
                 calls: [
                    .init(code: "getUserId()",
                          note: "Returns the current member ID; tapping the card or ‘Sync now’ reveals it with a shine sweep."),
                 ])
    }

    // MARK: Details form (setUserId / setEmail)

    private var detailsForm: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your details").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)

                PushMartField(placeholder: "MEMBER ID", text: $userId, icon: "person.fill")
                    .accessibilityIdentifier("userIdTextField")
                PushMartField(placeholder: "EMAIL", text: $email, icon: "envelope.fill")
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                PushMartButton(title: "Save changes", icon: "checkmark") { save() }
                    .sdkNote("Pushwoosh.configure.setUserId(_:) · setEmail(_:)",
                             "Tells Pushwoosh who this shopper is, so orders and offers follow them across devices.",
                             calls: [
                                .init(code: "setUserId(id)",
                                      note: "Sets the member ID typed in the form as the current user."),
                                .init(code: "setEmail(mail)",
                                      note: "Attaches the email so campaigns can also reach this shopper by email."),
                             ])

                Text("Your member ID and email tell PushMart who you are, so orders, offers and rewards follow you across devices.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Contact channels (omnichannel)

    private var channelsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Get order updates on").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)

                PushMartField(placeholder: "PHONE · +14155550100", text: $phone, icon: "phone.fill")
                    .keyboardType(.phonePad)
                PushMartButton(title: "Text me order updates", icon: "message.fill", style: .secondary) {
                    let n = phone.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty else { PushMartResult.shared.fail("No number", "Enter a phone number first."); return }
                    PushwooshHelper.safeCall { Pushwoosh.configure.registerSmsNumber(n) }
                    PushMartResult.shared.success("SMS updates on", n)
                }
                .sdkNote("Pushwoosh.configure.registerSmsNumber(_:)",
                         "Registers a phone number so PushMart can send order updates over SMS.",
                         calls: [
                            .init(code: "registerSmsNumber(n)",
                                  note: "Enrolls the entered phone number for SMS delivery."),
                         ])

                PushMartField(placeholder: "WHATSAPP · +14155550100", text: $whatsapp, icon: "bubble.left.fill")
                    .keyboardType(.phonePad)
                PushMartButton(title: "Message me on WhatsApp", icon: "checkmark.bubble.fill", style: .secondary) {
                    let n = whatsapp.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty else { PushMartResult.shared.fail("No number", "Enter a WhatsApp number first."); return }
                    PushwooshHelper.safeCall { Pushwoosh.configure.registerWhatsappNumber(n) }
                    PushMartResult.shared.success("WhatsApp updates on", n)
                }
                .sdkNote("Pushwoosh.configure.registerWhatsappNumber(_:)",
                         "Registers a number so PushMart can message this shopper on WhatsApp.",
                         calls: [
                            .init(code: "registerWhatsappNumber(n)",
                                  note: "Enrolls the entered number for WhatsApp delivery."),
                         ])

                Text("Use international format (e.g. +1…). We'll send order and delivery updates on the channels you pick.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Multiple emails & account merge (setEmails / setUser:emails: / mergeUserId)

    private var identityAdvancedCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Extra emails & merge").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)

                PushMartField(placeholder: "EMAILS · comma separated", text: $emails, icon: "envelope.badge.fill")
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                PushMartButton(title: "Register all emails", icon: "tray.and.arrow.down.fill", style: .secondary) {
                    let list = parsedEmails
                    guard !list.isEmpty else { PushMartResult.shared.fail("No emails", "Enter one or more emails, comma separated."); return }
                    PushwooshHelper.safeCall {
                        Pushwoosh.configure.setEmails(list) { error in
                            DispatchQueue.main.async {
                                if let error { PushMartResult.shared.fail("Emails failed", error.localizedDescription) }
                                else { PushMartResult.shared.success("Emails registered", list.joined(separator: ", ")) }
                            }
                        }
                    }
                }
                .sdkNote("Pushwoosh.configure.setEmails(_:completion:)",
                         "Registers several email addresses for the same shopper at once.",
                         calls: [
                            .init(code: "setEmails(list) { error in … }",
                                  note: "Sends the comma-separated emails; the completion reports success or the error."),
                         ])

                PushMartButton(title: "Link ID + these emails", icon: "person.badge.plus", style: .secondary) {
                    let id = userId.trimmingCharacters(in: .whitespacesAndNewlines)
                    let list = parsedEmails
                    guard !id.isEmpty, !list.isEmpty else { PushMartResult.shared.fail("Missing input", "Need a member ID and at least one email."); return }
                    PushwooshHelper.safeCall {
                        Pushwoosh.configure.setUser(id, emails: list) { error in
                            DispatchQueue.main.async {
                                if let error { PushMartResult.shared.fail("Link failed", error.localizedDescription) }
                                else { PushMartResult.shared.success("Linked", "\(id) · \(list.count) email(s)") }
                            }
                        }
                    }
                }
                .sdkNote("Pushwoosh.configure.setUser(_:emails:completion:)",
                         "Links a member ID and a set of emails to the same shopper in one call.",
                         calls: [
                            .init(code: "setUser(id, emails: list) { error in … }",
                                  note: "Associates the member ID with all entered emails; the completion reports the result."),
                         ])

                Divider().overlay(PushMart.textTertiary.opacity(0.3))

                PushMartField(placeholder: "PREVIOUS / ANONYMOUS ID", text: $oldUserId, icon: "arrow.triangle.merge")
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Toggle(isOn: $doMerge) {
                    Text("Merge past events into current member")
                        .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                }
                .tint(PushMart.coral)

                PushMartButton(title: "Merge into current member", icon: "arrow.triangle.merge", style: .secondary) { merge() }
                    .sdkNote("Pushwoosh.configure.mergeUserId(_:to:doMerge:completion:)",
                             "Moves an anonymous or previous session onto the signed-in member after login.",
                             calls: [
                                .init(code: "mergeUserId(old, to: current, doMerge: doMerge) { error in … }",
                                      note: "Merges the previous ID's history into the current member when the toggle is on, or just moves it across when off."),
                             ])

                Text("Register several emails for one shopper, or move an anonymous session's events onto the signed-in member after login.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var parsedEmails: [String] {
        emails.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func merge() {
        let old = oldUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        let current = Pushwoosh.configure.getUserId()
        guard !old.isEmpty else { PushMartResult.shared.fail("No previous ID", "Enter the anonymous or previous member ID."); return }
        guard !current.isEmpty else { PushMartResult.shared.fail("No current member", "Save a member ID first, then merge."); return }
        PushwooshHelper.safeCall {
            Pushwoosh.configure.mergeUserId(old, to: current, doMerge: doMerge) { error in
                DispatchQueue.main.async {
                    if let error { PushMartResult.shared.fail("Merge failed", error.localizedDescription) }
                    else { PushMartResult.shared.success(doMerge ? "Merged" : "Moved", "\(old) → \(current)") }
                }
            }
        }
    }

    // MARK: Actions — SDK contract preserved

    private func save() {
        let id = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !id.isEmpty || !mail.isEmpty else {
            PushMartResult.shared.fail("Nothing to save", "Add a member ID or email first.")
            return
        }

        if !id.isEmpty {
            Pushwoosh.configure.setUserId(id)
        }
        if !mail.isEmpty {
            Pushwoosh.configure.setEmail(mail)
            storedEmail = mail
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { justSaved = true }
        syncedNote = "Saved — syncing your card"
        sync(animated: true)
        PushMartResult.shared.success("Saved", "Your details are up to date.")
    }

    /// The "get" method, played as a card sync: pull the live member id and reveal it with a shine.
    private func sync(animated: Bool) {
        let result = Pushwoosh.configure.getUserId()
        memberId = result
        syncedNote = result.isEmpty ? "No member ID yet — save your details" : "Synced just now"

        guard animated else { return }
        shine = false
        withAnimation(.easeInOut(duration: 0.9)) { shine = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { justSaved = false }
        }
    }
}

#Preview {
    UserView()
}
