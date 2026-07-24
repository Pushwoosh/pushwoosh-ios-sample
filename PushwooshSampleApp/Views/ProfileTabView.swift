//
//  ProfileTabView.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI

// Account hub. Each row opens a real settings surface; the SDK-facing screens
// from the original demo live here and are re-skinned in later iterations.
struct ProfileTabView: View {
    @AppStorage(PushMartStore.userNameKey)  private var userName = ""
    @AppStorage(PushMartStore.userEmailKey) private var userEmail = ""
    @AppStorage(PushMartStore.onboardedKey) private var onboarded = false
    @State private var showSwitch = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    group("Account", [
                        .init("Account", "Name, email & user id", "person.crop.circle.fill", 0xFF5A5F, AnyView(UserView())),
                        .init("Push notifications", "Manage push registration", "bell.badge.fill", 0xFF8A3D, AnyView(RegistrationView())),
                        .init("Notifications", "Send & clear local alerts", "app.badge.fill", 0xFF4D5E, AnyView(NotificationsView())),
                        .init("App settings", "Language, alerts, access code", "gearshape.fill", 0x8E8E93, AnyView(SettingsView()))
                    ])
                    group("Shopping", [
                        .init("Shopping preferences", "Tune what you see", "slider.horizontal.3", 0xAF7BFF, AnyView(TagsView()))
                    ])
                    group("Data & privacy", [
                        .init("Data & sync", "Server communication", "antenna.radiowaves.left.and.right", 0x2BD98A, AnyView(CommunicationView())),
                        .init("Device", "Push token, HWID, app code", "iphone", 0x64D2FF, AnyView(DeviceInfoView())),
                        .init("Inbox data", "Raw inbox messages API", "tray.full.fill", 0x5AC8FA, AnyView(InboxDataView())),
                        .init("Rich media", "In-app message appearance", "sparkles.tv.fill", 0xFFC24B, AnyView(MediaView()))
                    ])
                    group("About", [
                        .init("About PushMart", "How offers & rewards work", "info.circle.fill", 0x8E8E93, AnyView(MonetizationView()))
                    ])
                    #if DEBUG
                    group("Developer", [
                        .init("Native in-apps", "Test every template", "bubble.left.and.bubble.right.fill", 0xAF52DE, AnyView(InAppMessagesView())),
                        .init("Developer tools", "Log level & diagnostics", "hammer.fill", 0x8E8E93, AnyView(DeveloperView()))
                    ])
                    #endif
                    switchAccountButton
                    signOut
                    Text("PushMart · Version 1.0.0")
                        .font(PushMart.body(12)).foregroundStyle(PushMart.textTertiary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 96)
            }
            .background(PushMartBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Text("Profile").font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary) } }
            .sheet(isPresented: $showSwitch) { SwitchAccountSheet() }
        }
        .tint(PushMart.coral)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Circle().fill(PushMart.brand).frame(width: 60, height: 60)
                .overlay(Text(initials).font(PushMart.title(24)).foregroundStyle(PushMart.ink))
            VStack(alignment: .leading, spacing: 3) {
                Text(userName.isEmpty ? "Guest" : userName).font(PushMart.title(20)).foregroundStyle(PushMart.textPrimary)
                Text(userEmail.isEmpty ? "Not signed in" : userEmail).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var initials: String {
        let base = userName.isEmpty ? "N" : userName
        return String(base.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }

    private var switchAccountButton: some View {
        Button { showSwitch = true } label: {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                Text("Switch account").font(PushMart.headline(15))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(PushMart.textTertiary)
            }
            .foregroundStyle(PushMart.textPrimary)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).fill(PushMart.surface)
                .overlay(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private var signOut: some View {
        Button {
            AccountManager.logout()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign out").font(PushMart.headline(15))
                Spacer()
            }
            .foregroundStyle(PushMart.danger)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).fill(PushMart.surface)
                .overlay(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private func group(_ title: String, _ rows: [ProfileRow]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(PushMart.label(12)).tracking(1.5).foregroundStyle(PushMart.textTertiary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                    NavigationLink { row.destination.navigationTitle(row.title) } label: { row.label }
                    if idx < rows.count - 1 { Divider().overlay(PushMart.stroke).padding(.leading, 60) }
                }
            }
            .background(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).fill(PushMart.surface)
                .overlay(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
        }
    }
}

struct ProfileRow: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let tintHex: UInt32
    let destination: AnyView

    init(_ title: String, _ subtitle: String, _ icon: String, _ tintHex: UInt32, _ destination: AnyView) {
        self.title = title; self.subtitle = subtitle; self.icon = icon; self.tintHex = tintHex; self.destination = destination
    }

    var label: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color(rgb: tintHex))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color(rgb: tintHex).opacity(0.16)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                Text(subtitle).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(PushMart.textTertiary)
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}
