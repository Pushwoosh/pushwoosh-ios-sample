//
//  CommunicationView.swift
//  PushMart
//

import SwiftUI
import PushwooshFramework

// Data & sync. Signature: one big connection-status hero with a single pause/
// resume control. Reflects and drives isServerCommunicationAllowed / start / stop.
struct CommunicationView: View {
    @State private var communicationEnabled = true

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    statusHero
                    note
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .onAppear {
            communicationEnabled = PushwooshHelper.safeCall(false) {
                Pushwoosh.configure.isServerCommunicationAllowed()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Data & sync").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("Control what PushMart syncs").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(.top, 4)
    }

    private var statusHero: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill((communicationEnabled ? PushMart.success : PushMart.textTertiary).opacity(0.16))
                    .frame(width: 108, height: 108)
                Image(systemName: communicationEnabled ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(communicationEnabled ? PushMart.success : PushMart.textTertiary)
            }
            VStack(spacing: 4) {
                Text(communicationEnabled ? "Syncing" : "Paused")
                    .font(PushMart.display(26)).foregroundStyle(PushMart.textPrimary)
                Text(communicationEnabled
                     ? "Your account, orders and offers stay up to date."
                     : "No data is sent or received while paused.")
                    .font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PushMartButton(title: communicationEnabled ? "Pause sync" : "Resume sync",
                           icon: communicationEnabled ? "pause.fill" : "play.fill",
                           style: communicationEnabled ? .secondary : .primary) {
                toggle()
            }
            .sdkNote("Pushwoosh.configure.startServerCommunication() / stopServerCommunication()",
                     "Pauses or resumes all data sync with Pushwoosh.",
                     calls: [
                        .init(code: "stopServerCommunication()",
                              note: "Pause - stops all network requests to Pushwoosh, including push delivery."),
                        .init(code: "startServerCommunication()",
                              note: "Resume - re-enables data sync and push delivery.")
                     ])
            Button {
                communicationEnabled = PushwooshHelper.safeCall(false) {
                    Pushwoosh.configure.isServerCommunicationAllowed()
                }
            } label: {
                Text("Check status").font(PushMart.label(13)).foregroundStyle(PushMart.coral)
            }
            .sdkNote("Pushwoosh.configure.isServerCommunicationAllowed()",
                     "Reads whether data sync with Pushwoosh is currently on.",
                     calls: [
                        .init(code: "isServerCommunicationAllowed()",
                              note: "Returns true while sync is active, false while paused.")
                     ])
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).fill(PushMart.surface)
            .overlay(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
    }

    private var note: some View {
        Text("Pausing stops all network requests to PushMart — including delivery of push notifications — until you resume.")
            .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    private func toggle() {
        let resume = !communicationEnabled
        if resume {
            PushwooshHelper.safeCall { Pushwoosh.configure.startServerCommunication() }
        } else {
            PushwooshHelper.safeCall { Pushwoosh.configure.stopServerCommunication() }
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { communicationEnabled = resume }
        PushMartResult.shared.success(resume ? "Sync resumed" : "Sync paused")
    }
}

#Preview {
    CommunicationView()
}
