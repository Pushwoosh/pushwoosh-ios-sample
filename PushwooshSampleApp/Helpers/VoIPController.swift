//
//  VoIPController.swift
//  PushMart
//
//  Created by André Kis
//

import Foundation
import Combine
import UIKit
import CallKit
import AVFoundation
import PushwooshFramework
import PushwooshVoIP

// VoIP (Pushwoosh.VoIP) call engine for the sample — drives the VoIP demo screen.
//
// The SDK owns the PKPushRegistry, CXProvider and CXCallController: configureVoIP() runs
// from the swizzled didFinishLaunchingWithOptions, creates them, registers the VoIP push
// token and reports incoming push calls to CallKit. The app must NOT create a second
// CXProvider or forward the VoIP token. The SDK hands us its own controller/provider via
// returnedCallController(_:) / returnedProvider(_:), which we capture here.
//
// Incoming calls arrive via voipDidReceiveIncomingCall(payload:) (server VoIP push).
// Outgoing calls are placed IN-APP: we request a CXStartCallAction on the SDK's
// CXCallController; the SDK's provider fulfills it and calls back through startCall(_:perform:),
// where we report the call connected. Because app-initiated calls aren't in the SDK's
// push-message map, ending them via CXEndCallAction would fail — we end them with
// provider.reportCall(with:endedAt:reason:) on the captured provider instead.
final class VoIPController: NSObject, ObservableObject, PWVoIPCallDelegate, CXCallObserverDelegate {

    static let shared = VoIPController()

    enum CallState: String { case idle = "Idle", dialing = "Dialing", connecting = "Connecting", incoming = "Incoming", active = "On call", ended = "Ended" }

    struct Event: Identifiable {
        enum Kind { case info, incoming, outgoing, state, error }
        let id = UUID()
        let time: Date
        let title: String
        let detail: String
        let kind: Kind
    }

    // Live state for the UI
    @Published private(set) var registration = "Not registered"
    @Published private(set) var providerReady = false
    @Published private(set) var callState: CallState = .idle
    @Published private(set) var activePeer = ""
    @Published private(set) var isMuted = false
    @Published private(set) var isOnHold = false
    @Published private(set) var isVideoCall = false
    @Published private(set) var connectedAt: Date?
    @Published private(set) var events: [Event] = []

    // Config (bound to the screen)
    @Published var supportsVideo = false
    @Published var ringtone = ""
    @Published var handleType = 2            // PWVoIPHandleType: generic=1, phoneNumber=2, email=3
    @Published var incomingTimeout: Double = 30

    private var callController: CXCallController?
    private weak var provider: CXProvider?
    private var activeCallUUID: UUID?
    private let callObserver = CXCallObserver()

    private override init() { super.init() }

    var isRinging: Bool { callState == .incoming }
    var hasActiveCall: Bool { activeCallUUID != nil && (callState == .dialing || callState == .connecting || callState == .active) }

    // MARK: - Setup / config

    func start() {
        guard !PushwooshHelper.isUITesting else { return }
        Pushwoosh.VoIP.delegate = self
        callObserver.setDelegate(self, queue: .main)
        Pushwoosh.VoIP.initializeVoIP(supportsVideo, ringtoneSound: ringtone, handleTypes: handleType)
        Pushwoosh.VoIP.setIncomingCallTimeout(incomingTimeout)
        log("VoIP started", "delegate set · initializeVoIP(video: \(supportsVideo), handleTypes: \(handleType))")
    }

    func applyConfig() {
        Pushwoosh.VoIP.initializeVoIP(supportsVideo, ringtoneSound: ringtone, handleTypes: handleType)
        Pushwoosh.VoIP.setIncomingCallTimeout(incomingTimeout)
        Pushwoosh.VoIP.setRingtone(ringtone)
        log("Config applied", "video: \(supportsVideo) · ringtone: \(ringtone.isEmpty ? "default" : ringtone) · handleTypes: \(handleType) · timeout: \(Int(incomingTimeout))s")
    }

    // MARK: - Outgoing call (in-app)

    func startOutgoingCall(to name: String, video: Bool = false) {
        guard !hasActiveCall else { return }
        let peer = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Demo contact" : name
        let uuid = UUID()
        activeCallUUID = uuid
        activePeer = peer
        isMuted = false
        isOnHold = false
        isVideoCall = video
        callState = .dialing

        let handle = CXHandle(type: cxHandleType(), value: peer)
        let action = CXStartCallAction(call: uuid, handle: handle)
        action.isVideo = video
        request(CXTransaction(action: action),
                ok: { self.log("Outgoing call requested", "CXStartCallAction → \(peer)", kind: .outgoing) },
                fail: { err in
                    self.callState = .idle
                    self.activeCallUUID = nil
                    self.activePeer = ""
                    self.log("Start call failed", err, kind: .error)
                })
    }

    func endActiveCall() {
        guard let uuid = activeCallUUID else { return }
        // App-initiated calls aren't in the SDK's push map, so CXEndCallAction would fail.
        provider?.reportCall(with: uuid, endedAt: nil, reason: .remoteEnded)
        connectedAt = nil
        callState = .ended
        log("Call ended", "provider.reportCall(endedAt:reason: .remoteEnded)", kind: .state)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.callState == .ended else { return }
            self.resetToIdle()
        }
    }

    // MARK: - Simulated incoming call (in-app)
    //
    // A real incoming call arrives from a server VoIP push and rings through the SDK's
    // own CXProvider. This local simulation drives the same delegate-facing state so the
    // demo can show the incoming UI + answer/decline flow without a server round-trip.

    func simulateIncomingCall(from name: String = "Maya · PushMart Care", video: Bool = false) {
        guard callState == .idle || callState == .ended else { return }
        activeCallUUID = UUID()
        activePeer = name
        isVideoCall = video
        isMuted = false
        isOnHold = false
        callState = .incoming
        log("Incoming call (simulated)", "caller: \(name) · video: \(video)", kind: .incoming)
    }

    func answerIncoming() {
        guard callState == .incoming else { return }
        callState = .active
        connectedAt = Date()
        log("Answered", "incoming call answered", kind: .state)
    }

    func declineIncoming() {
        guard callState == .incoming else { return }
        log("Declined", "incoming call declined", kind: .state)
        resetToIdle()
    }

    // Callback request: in production the app posts an event and the backend places a VoIP
    // call back to the user. Here we log the request and, after a short delay, ring a
    // simulated incoming call so the demo shows the full request → callback loop.
    func requestCallback(from name: String = "Maya · PushMart Care", after seconds: TimeInterval = 5, video: Bool = false) {
        log("Callback requested", "the team calls back in ~\(Int(seconds))s — background the app to see the native call", kind: .info)
        // Route through the native CallKit path (reportNewIncomingCall + background task),
        // NOT the in-app simulation — the callback must ring as a real system call.
        scheduleBackgroundIncoming(from: name, after: seconds, video: video)
    }

    // Rings a REAL system incoming call after a delay by reporting it to the SDK's
    // CXProvider — CallKit shows the incoming-call screen even while the app is
    // backgrounded, exactly as a server VoIP push would. Note: because this call is not
    // in the SDK's push-message map, answering it through the system UI won't fully
    // connect (the SDK's answer handler needs the push payload); a real answerable
    // backgrounded call comes from a server VoIP push. Decline/end are caught by CXCallObserver.
    func scheduleBackgroundIncoming(from name: String = "Maya · PushMart Care", after seconds: TimeInterval = 8, video: Bool = false) {
        guard callState == .idle || callState == .ended else { return }
        guard let provider = provider else {
            log("Can't ring", "CallKit provider not ready yet", kind: .error)
            return
        }
        let uuid = UUID()
        activeCallUUID = uuid
        log("Background call scheduled", "rings in ~\(Int(seconds))s — background the app now", kind: .info)

        // A main-queue timer is suspended together with the app, so it would only fire once
        // the app returns to the foreground (ringing in-app). Hold a background task so the
        // timer still fires while backgrounded; then reportNewIncomingCall presents the
        // system incoming-call screen over the lock screen. beginBackgroundTask buys ~30s,
        // enough for this short delay; a call that must arrive at any time still needs a
        // real server VoIP push (a local timer can't wake a suspended/terminated app).
        var bgTask = UIBackgroundTaskIdentifier.invalid
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "pw.backgroundIncoming") {
            if bgTask != .invalid { UIApplication.shared.endBackgroundTask(bgTask); bgTask = .invalid }
        }
        let endTask = {
            if bgTask != .invalid { UIApplication.shared.endBackgroundTask(bgTask); bgTask = .invalid }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let self, self.activeCallUUID == uuid else { endTask(); return }
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: name)
            update.localizedCallerName = name
            update.hasVideo = video
            provider.reportNewIncomingCall(with: uuid, update: update) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.log("reportNewIncomingCall failed", error.localizedDescription, kind: .error)
                        self.resetToIdle()
                    } else {
                        // Do NOT flip callState to .incoming here — CallKit owns the native
                        // ring UI. The in-app state follows via CXCallObserver (connect/end).
                        self.activePeer = name
                        self.isVideoCall = video
                        self.log("Incoming call (system)", "reportNewIncomingCall — CallKit shows the native call", kind: .incoming)
                    }
                    endTask()
                }
            }
        }
    }

    private func resetToIdle() {
        callState = .idle
        activePeer = ""
        activeCallUUID = nil
        isMuted = false
        isOnHold = false
        isVideoCall = false
        connectedAt = nil
    }

    func toggleMute() {
        guard let uuid = activeCallUUID else { return }
        let next = !isMuted
        request(CXTransaction(action: CXSetMutedCallAction(call: uuid, muted: next)),
                ok: { self.isMuted = next; self.log(next ? "Muted" : "Unmuted", "CXSetMutedCallAction(\(next))") },
                fail: { err in self.log("Mute failed", err, kind: .error) })
    }

    func toggleHold() {
        guard let uuid = activeCallUUID else { return }
        let next = !isOnHold
        request(CXTransaction(action: CXSetHeldCallAction(call: uuid, onHold: next)),
                ok: { self.isOnHold = next; self.log(next ? "On hold" : "Resumed", "CXSetHeldCallAction(\(next))") },
                fail: { err in self.log("Hold failed", err, kind: .error) })
    }

    private func request(_ tx: CXTransaction, ok: @escaping () -> Void, fail: @escaping (String) -> Void) {
        let controller = callController ?? CXCallController()
        controller.request(tx) { error in
            DispatchQueue.main.async { if let error { fail(error.localizedDescription) } else { ok() } }
        }
    }

    private func cxHandleType() -> CXHandle.HandleType {
        switch handleType {
        case 2: return .phoneNumber
        case 3: return .emailAddress
        default: return .generic
        }
    }

    // MARK: - PWVoIPCallDelegate: SDK-owned CallKit objects

    func returnedCallController(_ controller: CXCallController) {
        callController = controller
        log("Received CXCallController", "returnedCallController(_:)")
    }

    func returnedProvider(_ provider: CXProvider) {
        self.provider = provider
        DispatchQueue.main.async { self.providerReady = true }
        log("Received CXProvider", "returnedProvider(_:)")
    }

    // MARK: - CXCallObserver
    //
    // Catches call-state changes from any source — crucially the native CallKit UI's
    // hang-up. App-initiated outgoing calls aren't in the SDK's push map, so the SDK
    // provider's CXEndCallAction handler fails and never notifies us; the observer does.
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        guard let uuid = activeCallUUID, call.uuid == uuid else { return }
        if call.hasEnded {
            log("Call ended (system)", "CXCallObserver — call left CallKit", kind: .state)
            resetToIdle()
        } else if call.hasConnected {
            if callState != .active {
                callState = .active
                log("Call connected (system)", "CXCallObserver hasConnected", kind: .state)
            }
            if connectedAt == nil { connectedAt = Date() }
        }
    }

    // MARK: - PWVoIPCallDelegate: token registration

    func voipDidRegisterTokenSuccessfully() {
        DispatchQueue.main.async { self.registration = "Registered" }
        log("Token registered", "voipDidRegisterTokenSuccessfully()")
    }

    func voipDidFailToRegisterToken(error: Error) {
        DispatchQueue.main.async { self.registration = "Failed" }
        log("Token registration failed", error.localizedDescription, kind: .error)
    }

    // MARK: - PWVoIPCallDelegate: incoming (push-driven)

    func voipDidReceiveIncomingCall(payload: PWVoIPMessage) {
        DispatchQueue.main.async {
            self.activePeer = payload.callerName
            self.callState = .incoming
            self.isVideoCall = payload.hasVideo
            self.activeCallUUID = UUID(uuidString: payload.uuid)
        }
        log("Incoming call", "caller: \(payload.callerName) · video: \(payload.hasVideo) · callId: \(payload.callId ?? "nil")", kind: .incoming)
    }

    func voipDidReportIncomingCallSuccessfully(voipMessage: PWVoIPMessage) {
        log("Incoming reported to CallKit", "caller: \(voipMessage.callerName)", kind: .incoming)
    }

    func voipDidFailToReportIncomingCall(error: Error) {
        log("Report incoming failed", error.localizedDescription, kind: .error)
    }

    func voipDidCancelCall(voipMessage: PWVoIPMessage) {
        DispatchQueue.main.async { self.resetToIdle() }
        log("Call cancelled", "caller: \(voipMessage.callerName)", kind: .state)
    }

    func voipDidFailToCancelCall(callId: String?, reason: String) {
        log("Cancel failed", "callId: \(callId ?? "nil") · \(reason)", kind: .error)
    }

    // MARK: - PWVoIPCallDelegate: CallKit actions routed back from the SDK provider

    func startCall(_ provider: CXProvider, perform action: CXStartCallAction) {
        // The SDK already fulfilled the action; we only report outgoing progress.
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        DispatchQueue.main.async { self.callState = .connecting }
        log("startCall", "reportOutgoingCall(startedConnectingAt:) → \(action.handle.value)", kind: .outgoing)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self, self.activeCallUUID == action.callUUID else { return }
            provider.reportOutgoingCall(with: action.callUUID, connectedAt: nil)
            self.callState = .active
            self.connectedAt = Date()
            self.log("Call connected", "reportOutgoingCall(connectedAt:)", kind: .outgoing)
        }
    }

    func answerCall(_ provider: CXProvider, perform action: CXAnswerCallAction, voipMessage: PWVoIPMessage?) {
        DispatchQueue.main.async { self.callState = .active; self.connectedAt = Date() }
        log("Answer call", "caller: \(voipMessage?.callerName ?? "nil")", kind: .state)
    }

    func endCall(_ provider: CXProvider, perform action: CXEndCallAction, voipMessage: PWVoIPMessage?) {
        DispatchQueue.main.async { self.resetToIdle() }
        log("End call", "caller: \(voipMessage?.callerName ?? "nil")", kind: .state)
    }

    func mutedCall(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        DispatchQueue.main.async { self.isMuted = action.isMuted }
        log("Muted changed", "isMuted: \(action.isMuted)")
    }

    func heldCall(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        DispatchQueue.main.async { self.isOnHold = action.isOnHold }
        log("Held changed", "isOnHold: \(action.isOnHold)")
    }

    func playDTMF(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        log("Play DTMF", "digits: \(action.digits)")
    }

    // MARK: - PWVoIPCallDelegate: provider / audio-session lifecycle

    func activatedAudioSession(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        log("Audio session activated")
    }

    func deactivatedAudioSession(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        log("Audio session deactivated")
    }

    func pwProviderDidReset(_ provider: CXProvider) {
        DispatchQueue.main.async { self.providerReady = false; self.resetToIdle() }
        log("Provider did reset", "providerDidReset(_:)", kind: .state)
    }

    func pwProviderDidBegin(_ provider: CXProvider) {
        DispatchQueue.main.async { self.providerReady = true }
        log("Provider did begin", "providerDidBegin(_:)", kind: .state)
    }

    // MARK: - Logging

    func clearLog() { events.removeAll() }

    private func log(_ title: String, _ detail: String = "", kind: Event.Kind = .info) {
        let event = Event(time: Date(), title: title, detail: detail, kind: kind)
        DispatchQueue.main.async {
            self.events.insert(event, at: 0)
            if self.events.count > 60 { self.events.removeLast(self.events.count - 60) }
        }
        print("[VoIP] \(title)\(detail.isEmpty ? "" : " — \(detail)")")
    }
}
