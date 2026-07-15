//
//  DeviceInfoView.swift
//  PushMart
//

import SwiftUI
import UIKit
import PushwooshFramework

// Device screen. Signature: a "device passport" card with the push token, device
// id and app code — copyable, refreshed inline. Read-only (getters only).
struct DeviceInfoView: View {
    @State private var pushToken = ""
    @State private var deviceId = ""
    @State private var appCode = ""

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    passport
                        .sdkNote("Pushwoosh.configure.getPushToken()",
                                 "Reads this device's push token, device id and store access code.",
                                 calls: [
                                    .init(code: "Pushwoosh.configure.getPushToken()",
                                          note: "Current APNs push token, or nil if the device isn't registered."),
                                    .init(code: "Pushwoosh.configure.getHWID()",
                                          note: "Pushwoosh device (hardware) id for this install."),
                                    .init(code: "Pushwoosh.configure.getApplicationCode()",
                                          note: "The Pushwoosh application code this device is registered to.")
                                 ])
                    note
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .onAppear(perform: load)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Device").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("How PushMart identifies this device").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(.top, 4)
    }

    private var passport: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(PushMart.brand)
                        .frame(width: 46, height: 46)
                        .overlay(Image(systemName: "iphone").font(.system(size: 22, weight: .bold)).foregroundStyle(PushMart.ink))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Device passport").font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                        Text("Read-only").font(PushMart.body(12)).foregroundStyle(PushMart.textTertiary)
                    }
                    Spacer()
                    Button(action: load) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 14, weight: .bold))
                            .foregroundStyle(PushMart.textPrimary).padding(9)
                            .background(Circle().fill(PushMart.surfaceHi))
                    }
                }
                row("Push token", pushToken, "key.fill")
                Divider().overlay(PushMart.stroke)
                row("Device ID", deviceId, "cpu")
                Divider().overlay(PushMart.stroke)
                row("Store access code", appCode, "qrcode")
            }
        }
    }

    private func row(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundStyle(PushMart.coral)
                Text(label.uppercased()).font(PushMart.label(11)).tracking(1).foregroundStyle(PushMart.textTertiary)
                Spacer()
                if !value.isEmpty {
                    Button {
                        UIPasteboard.general.string = value
                        PushMartResult.shared.success("Copied", label)
                    } label: {
                        Image(systemName: "doc.on.doc").font(.system(size: 12, weight: .semibold)).foregroundStyle(PushMart.textSecondary)
                    }
                }
            }
            Text(value.isEmpty ? "Not available" : value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(value.isEmpty ? PushMart.textTertiary : PushMart.textPrimary)
                .textSelection(.enabled)
                .lineLimit(3).truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var note: some View {
        Text("These identifiers let PushMart deliver notifications and orders to this device. Nothing here identifies you personally.")
            .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    private func load() {
        pushToken = PushwooshHelper.safeCall(nil) { Pushwoosh.configure.getPushToken() } ?? ""
        deviceId = PushwooshHelper.safeCall("") { Pushwoosh.configure.getHWID() }
        appCode = PushwooshHelper.safeCall(nil) { Pushwoosh.configure.getApplicationCode() } ?? ""
    }
}

// Shared across several screens (LiveActivities, Media, Monetization). Keep here.
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
