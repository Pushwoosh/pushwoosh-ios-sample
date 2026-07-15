//
//  SupportView.swift
//  PushMart
//
//  Created by André Kis
//
//  "PushMart Care" — the Support tab. A branded care line: the shopper voice- or
//  video-calls a specialist, or simulates an incoming call. Outgoing calls are real
//  CallKit calls placed through the SDK's CXCallController (Pushwoosh.VoIP); incoming
//  server VoIP pushes surface here too. The signature is a live "presence ring" around
//  the specialist that changes colour and rhythm with the call state. Controls, config
//  and the raw PWVoIPCallDelegate event log sit behind an "SDK & call log" disclosure so
//  the screen reads as a real support surface. VoIP wiring: Helpers/VoIPController.swift.
//

import SwiftUI
import PushwooshFramework

struct SupportView: View {
    @ObservedObject private var voip = VoIPController.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let agent = "Maya · PushMart Care"
    private let mint = Color(rgb: 0x2BD98A)

    private struct Topic: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let tint: UInt32
        let event: String
    }
    private let topics: [Topic] = [
        .init(title: "Order status", subtitle: "Track a recent order", icon: "shippingbox.fill", tint: 0xFF8A3D, event: "support_order_status"),
        .init(title: "Returns & refunds", subtitle: "Start or check a return", icon: "arrow.uturn.left.circle.fill", tint: 0xAF7BFF, event: "support_returns"),
        .init(title: "Payments", subtitle: "Cards, receipts, charges", icon: "creditcard.fill", tint: 0x64D2FF, event: "support_payments"),
        .init(title: "Account help", subtitle: "Login & profile", icon: "person.crop.circle.fill", tint: 0xFF5A5F, event: "support_account")
    ]

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    eyebrow
                    callPanel
                    topicsCard
                    sdkDisclosure
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 96)
            }
        }
        .dismissKeyboardOnTap()
    }

    // MARK: State colour / label

    private var stateColor: Color {
        switch voip.callState {
        case .idle: return mint
        case .incoming: return PushMart.coral
        case .dialing, .connecting: return PushMart.tangerine
        case .active: return mint
        case .ended: return PushMart.textTertiary
        }
    }

    private var eyebrow: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("PUSHMART CARE").font(PushMart.label(12)).tracking(2).foregroundStyle(PushMart.textTertiary)
            Text("How can we help?").font(PushMart.display(30)).foregroundStyle(PushMart.textPrimary)
        }
        .padding(.top, 4)
    }

    // MARK: Call panel (the hero)

    private var callPanel: some View {
        VStack(spacing: 22) {
            stage
            actionZone
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(PushMart.surface)
                .overlay(alignment: .top) {
                    RadialGradient(colors: [stateColor.opacity(0.18), .clear], center: .top, startRadius: 8, endRadius: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1))
        )
        .animation(.easeInOut(duration: 0.35), value: voip.callState)
        .sdkNote(
            "Pushwoosh.VoIP — voice / video / callback",
            "Voice and Video place a real CallKit call; Call me back requests a callback.",
            docs: "Outgoing calls request a CXStartCallAction (isVideo for video) on the SDK's CXCallController; the call is reported connected in startCall(_:perform:). Call me back posts request_callback and, in this demo, rings a simulated incoming call to model the backend calling back.",
            calls: [
                SDKCallItem(code: "startOutgoingCall(to:video:) → CXStartCallAction", note: "Voice (isVideo:false) / Video (isVideo:true) via the SDK CXCallController."),
                SDKCallItem(code: "postEvent(\"request_callback\", withAttributes: [\"channel\": \"support\"])", note: "Call me back — signals the backend to place a VoIP call to the user."),
                SDKCallItem(code: "returnedCallController(_:) / returnedProvider(_:)", note: "SDK hands the app its CXCallController + CXProvider.")
            ]
        )
    }

    private var stage: some View {
        VStack(spacing: 14) {
            ZStack {
                PresenceRing(color: stateColor, period: voip.isRinging ? 1.0 : 1.9, animate: !reduceMotion && voip.callState != .ended)
                Circle()
                    .fill(PushMart.brandHorizontal)
                    .frame(width: 92, height: 92)
                    .overlay(
                        Group {
                            if voip.hasActiveCall || voip.isRinging {
                                Image(systemName: voip.isVideoCall ? "video.fill" : "phone.fill")
                                    .font(.system(size: 32, weight: .semibold)).foregroundStyle(PushMart.ink)
                            } else {
                                Text("M").font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundStyle(PushMart.ink)
                            }
                        }
                    )
                    .shadow(color: stateColor.opacity(0.4), radius: 18, y: 8)
            }
            .frame(width: 156, height: 156)

            Text(peerTitle).font(PushMart.title(21)).foregroundStyle(PushMart.textPrimary)
            statusLine
        }
    }

    private var peerTitle: String {
        if voip.hasActiveCall || voip.isRinging {
            return voip.activePeer.isEmpty ? "Maya" : String(voip.activePeer.split(separator: "·").first ?? "Maya").trimmingCharacters(in: .whitespaces)
        }
        return "Maya"
    }

    @ViewBuilder private var statusLine: some View {
        switch voip.callState {
        case .idle, .ended:
            HStack(spacing: 6) {
                Circle().fill(mint).frame(width: 8, height: 8)
                Text("Online · replies in ~2 min").font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
            }
        case .incoming:
            HStack(spacing: 8) {
                Text("Incoming call").font(PushMart.label(13)).foregroundStyle(PushMart.coral)
                if voip.isVideoCall { videoBadge }
            }
        case .dialing, .connecting:
            Text("\(voip.callState.rawValue)…").font(PushMart.label(13)).foregroundStyle(PushMart.tangerine)
        case .active:
            HStack(spacing: 8) {
                if let start = voip.connectedAt {
                    TimelineView(.periodic(from: start, by: 1)) { ctx in
                        Text(elapsed(from: start, to: ctx.date))
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(PushMart.textPrimary)
                    }
                } else {
                    Text("Connected").font(PushMart.label(13)).foregroundStyle(mint)
                }
                if voip.isVideoCall { videoBadge }
            }
        }
    }

    private var videoBadge: some View {
        Text("VIDEO").font(PushMart.label(10)).tracking(1).foregroundStyle(PushMart.ink)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(PushMart.coral))
    }

    // MARK: Action zone (morphs by state)

    @ViewBuilder private var actionZone: some View {
        if voip.isRinging {
            incomingControls
        } else if voip.hasActiveCall {
            activeControls
        } else {
            idleControls
        }
    }

    private var idleControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                callButton("Voice", "phone.fill", fill: AnyShapeStyle(PushMart.surfaceHi), fg: PushMart.textPrimary, bordered: true) {
                    voip.startOutgoingCall(to: agent, video: false)
                }
                .accessibilityIdentifier("support.voiceCall")
                callButton("Video", "video.fill", fill: AnyShapeStyle(PushMart.brandHorizontal), fg: PushMart.ink, bordered: false) {
                    voip.startOutgoingCall(to: agent, video: true)
                }
                .accessibilityIdentifier("support.videoCall")
            }
            Button { sendCallback() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "phone.arrow.down.left.fill").font(.system(size: 15, weight: .semibold))
                    Text("Call me back").font(PushMart.headline(15))
                }
                .foregroundStyle(PushMart.textPrimary)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous)
                    .fill(PushMart.surfaceHi)
                    .overlay(RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("support.callMeBack")
        }
    }

    private func sendCallback() {
        PushwooshHelper.safeCall {
            PWInAppManager.shared().postEvent("request_callback", withAttributes: ["channel": "support"])
        }
        PushMartResult.shared.success("Callback requested", "Background the app — the call rings as a native call in a few seconds.")
        voip.requestCallback(from: agent, video: voip.supportsVideo)
    }

    private func callButton(_ title: String, _ icon: String, fill: AnyShapeStyle, fg: Color, bordered: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                Text(title).font(PushMart.headline(16))
            }
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous).fill(fill)
                    .overlay(RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: bordered ? 1 : 0))
            )
        }
        .buttonStyle(.plain)
    }

    private var incomingControls: some View {
        HStack(spacing: 48) {
            roundAction("Decline", "phone.down.fill", PushMart.danger) { voip.declineIncoming() }
                .accessibilityIdentifier("support.declineCall")
            roundAction("Answer", voip.isVideoCall ? "video.fill" : "phone.fill", mint) { voip.answerIncoming() }
                .accessibilityIdentifier("support.answerCall")
        }
    }

    private func roundAction(_ title: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: icon).font(.system(size: 26, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 66, height: 66).background(Circle().fill(color))
                    .shadow(color: color.opacity(0.45), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            Text(title).font(PushMart.label(12)).foregroundStyle(PushMart.textSecondary)
        }
    }

    private var activeControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                controlButton(voip.isMuted ? "Unmute" : "Mute", voip.isMuted ? "mic.slash.fill" : "mic.fill", active: voip.isMuted) { voip.toggleMute() }
                controlButton(voip.isOnHold ? "Resume" : "Hold", voip.isOnHold ? "play.fill" : "pause.fill", active: voip.isOnHold) { voip.toggleHold() }
            }
            Button { voip.endActiveCall() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "phone.down.fill")
                    Text("End call").font(PushMart.headline(16))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous).fill(PushMart.danger))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("support.endCall")
        }
    }

    private func controlButton(_ title: String, _ icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(title).font(PushMart.label(12))
            }
            .foregroundStyle(active ? PushMart.ink : PushMart.textPrimary)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous)
                .fill(active ? AnyShapeStyle(PushMart.brandHorizontal) : AnyShapeStyle(PushMart.surfaceHi))
                .overlay(RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private func elapsed(from start: Date, to now: Date) -> String {
        let total = max(0, Int(now.timeIntervalSince(start)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: Topics

    private var topicsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular topics").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                ForEach(Array(topics.enumerated()), id: \.element.id) { idx, topic in
                    Button { sendTopic(topic) } label: { topicRow(topic) }.buttonStyle(.plain)
                    if idx < topics.count - 1 { Divider().overlay(PushMart.stroke).padding(.leading, 52) }
                }
            }
        }
        .sdkNote(
            "PWInAppManager.shared().postEvent(_:withAttributes:)",
            "Tapping a topic posts a support event so Pushwoosh can route or trigger a help journey.",
            calls: [
                SDKCallItem(code: "postEvent(\"support_order_status\", withAttributes: [\"channel\": \"support\"])", note: "Fires the matching support-topic event with a channel attribute.")
            ]
        )
    }

    private func topicRow(_ topic: Topic) -> some View {
        HStack(spacing: 12) {
            Image(systemName: topic.icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(rgb: topic.tint))
                .frame(width: 36, height: 36).background(Circle().fill(Color(rgb: topic.tint).opacity(0.16)))
            VStack(alignment: .leading, spacing: 2) {
                Text(topic.title).font(PushMart.headline(15)).foregroundStyle(PushMart.textPrimary)
                Text(topic.subtitle).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(PushMart.textTertiary)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    private func sendTopic(_ topic: Topic) {
        PushwooshHelper.safeCall {
            PWInAppManager.shared().postEvent(topic.event, withAttributes: ["channel": "support"])
        }
        PushMartResult.shared.success("Request sent", "\(topic.title) — the PushMart Care team will pick it up.")
    }

    // MARK: SDK details (config + event log)

    private var sdkDisclosure: some View {
        PushMartCard {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 14) {
                    configSection
                    Divider().overlay(PushMart.stroke)
                    logSection
                }
                .padding(.top, 12)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(PushMart.coral)
                    Text("SDK & call log").font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                }
            }
            .tint(PushMart.coral)
        }
    }

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            statRow("VoIP token", voip.registration, "key.fill")
            statRow("CallKit provider", voip.providerReady ? "Ready" : "Waiting", "phone.connection.fill")

            HStack {
                Text("Default to video").font(PushMart.body(15)).foregroundStyle(PushMart.textPrimary)
                Spacer()
                Toggle("", isOn: $voip.supportsVideo).labelsHidden().tint(PushMart.coral)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Handle type").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                Picker("Handle type", selection: $voip.handleType) {
                    Text("Generic").tag(1); Text("Phone").tag(2); Text("Email").tag(3)
                }
                .pickerStyle(.segmented)
            }

            PushMartField(placeholder: "Ringtone file (optional)", text: $voip.ringtone, icon: "music.note")

            Stepper(value: $voip.incomingTimeout, in: 10...120, step: 5) {
                HStack {
                    Text("Incoming timeout").font(PushMart.body(15)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    Text("\(Int(voip.incomingTimeout))s").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(PushMart.coral)
                }
            }

            PushMartButton(title: "Apply configuration", icon: "checkmark.circle", style: .secondary) { voip.applyConfig() }

            Button { voip.simulateIncomingCall(from: agent, video: voip.supportsVideo) } label: {
                HStack(spacing: 7) {
                    Image(systemName: "phone.arrow.down.left.fill").font(.system(size: 13, weight: .semibold))
                    Text("Simulate in-app incoming (dev)").font(PushMart.label(13))
                }
                .foregroundStyle(PushMart.textSecondary).padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("support.simulateIncoming")

            Button { voip.scheduleBackgroundIncoming(from: agent, video: voip.supportsVideo) } label: {
                HStack(spacing: 7) {
                    Image(systemName: "moon.zzz.fill").font(.system(size: 13, weight: .semibold))
                    Text("Ring me in the background (8s)").font(PushMart.label(13))
                }
                .foregroundStyle(PushMart.textSecondary).padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("support.backgroundIncoming")
            Text("Tap, then send the app to the background — the call rings in ~8s over the lock screen, like a real VoIP push. Local demo: answering it won't connect (a real answerable call comes from a server push); decline/end work.")
                .font(PushMart.body(11.5)).foregroundStyle(PushMart.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sdkNote(
            "Pushwoosh.VoIP.initializeVoIP / setIncomingCallTimeout / setRingtone",
            "Applies VoIP setup: default video, handle type, ringtone and incoming-call timeout.",
            calls: [
                SDKCallItem(code: "Pushwoosh.VoIP.initializeVoIP(_:ringtoneSound:handleTypes:)", note: "Video flag, ringtone and handle type."),
                SDKCallItem(code: "Pushwoosh.VoIP.setIncomingCallTimeout(_:)", note: "Auto-marks an unanswered incoming call as missed."),
                SDKCallItem(code: "Pushwoosh.VoIP.setRingtone(_:)", note: "Custom ringtone for incoming calls.")
            ]
        )
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Event log").font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                Spacer()
                if !voip.events.isEmpty {
                    Button { voip.clearLog() } label: { Text("Clear").font(PushMart.label(13)).foregroundStyle(PushMart.coral) }
                }
            }
            if voip.events.isEmpty {
                Text("Delegate callbacks land here — start a call, simulate an incoming one, or send a VoIP push.")
                    .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(voip.events) { event in
                    eventRow(event)
                    if event.id != voip.events.last?.id { Divider().overlay(PushMart.stroke) }
                }
            }
        }
        .sdkNote(
            "PWVoIPCallDelegate — call lifecycle",
            "Every incoming and outgoing call callback is logged here.",
            calls: [
                SDKCallItem(code: "voipDidReceiveIncomingCall(payload:)", note: "A server VoIP push arrived and rings via CallKit."),
                SDKCallItem(code: "answerCall / endCall / mutedCall / heldCall(_:perform:...)", note: "CallKit actions routed back from the SDK provider."),
                SDKCallItem(code: "pwProviderDidBegin(_:) / pwProviderDidReset(_:)", note: "SDK CallKit provider lifecycle.")
            ]
        )
    }

    private func statRow(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(PushMart.coral).frame(width: 20)
            Text(label).font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
            Spacer()
            Text(value).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(PushMart.textPrimary)
        }
    }

    private func eventRow(_ event: VoIPController.Event) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(color(for: event.kind)).frame(width: 8, height: 8).padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.title).font(PushMart.headline(14)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    Text(Self.timeFormatter.string(from: event.time)).font(PushMart.body(11)).foregroundStyle(PushMart.textTertiary)
                }
                if !event.detail.isEmpty {
                    Text(event.detail)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(PushMart.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 3)
    }

    private func color(for kind: VoIPController.Event.Kind) -> Color {
        switch kind {
        case .info: return PushMart.textTertiary
        case .incoming: return mint
        case .outgoing: return PushMart.coral
        case .state: return Color(rgb: 0x64D2FF)
        case .error: return PushMart.danger
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f
    }()
}

// MARK: - Presence ring (signature)

/// Two sonar rings that expand and fade around the specialist avatar — a live "line".
/// Colour and speed are driven by call state; static (no pulse) when reduce-motion is on.
private struct PresenceRing: View {
    let color: Color
    let period: Double
    let animate: Bool

    @State private var pulse = false

    var body: some View {
        ZStack {
            ring(scale: pulse ? 1.35 : 1.0, opacity: pulse ? 0 : 0.5, line: 2)
            ring(scale: pulse ? 1.18 : 0.92, opacity: pulse ? 0 : 0.85, line: 2.5)
            Circle().strokeBorder(color.opacity(0.28), lineWidth: 1).frame(width: 118, height: 118)
        }
        .onAppear {
            guard animate else { return }
            withAnimation(.easeOut(duration: period).repeatForever(autoreverses: false)) { pulse = true }
        }
    }

    private func ring(scale: CGFloat, opacity: Double, line: CGFloat) -> some View {
        Circle().stroke(color.opacity(0.6), lineWidth: line)
            .frame(width: 118, height: 118)
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

#Preview {
    SupportView()
}
