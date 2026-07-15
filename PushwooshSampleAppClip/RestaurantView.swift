//
//  RestaurantView.swift
//  PushwooshSampleAppClip
//
//  Created by André Kis on 19.3.26.
//

import SwiftUI
import PushwooshFramework

struct RestaurantView: View {
    @State private var orderPlaced = false
    @State private var pushToken: String?
    @State private var sdkReady = false
    @State private var showDebug = false
    @State private var lastPush: (title: String, body: String)?
    @State private var showPushBanner = false
    @State private var selectedItem: MenuItem? = nil

    struct MenuItem: Identifiable {
        let id = UUID()
        let name: String
        let price: String
        let icon: String
        let color: Color
        let description: String
    }

    private let menuItems = [
        MenuItem(name: "Flat White", price: "$4.50", icon: "cup.and.saucer.fill", color: Color(red: 0.6, green: 0.4, blue: 0.25), description: "Double ristretto with velvety steamed milk"),
        MenuItem(name: "Avocado Toast", price: "$8.90", icon: "leaf.fill", color: Color(red: 0.35, green: 0.65, blue: 0.35), description: "Sourdough, smashed avo, chili flakes, poached egg"),
        MenuItem(name: "Croissant", price: "$3.20", icon: "birthday.cake.fill", color: Color(red: 0.85, green: 0.6, blue: 0.25), description: "Butter croissant, baked fresh every morning"),
        MenuItem(name: "Fresh Juice", price: "$5.50", icon: "drop.fill", color: Color(red: 0.9, green: 0.45, blue: 0.3), description: "Orange, carrot & ginger pressed to order"),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.95, blue: 0.92)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    heroImageSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    menuSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    orderSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    Spacer(minLength: 40)
                }
            }

            if showPushBanner, let push = lastPush {
                pushBannerOverlay(title: push.title, body: push.body)
            }
        }
        .onAppear {
            registerForPush()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pushReceived)) { notification in
            if let userInfo = notification.userInfo {
                lastPush = (
                    title: userInfo["title"] as? String ?? "",
                    body: userInfo["body"] as? String ?? ""
                )
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showPushBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation(.easeOut(duration: 0.3)) { showPushBanner = false }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "smallcircle.filled.circle")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.35))

                        Text("APP CLIP")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.35))
                            .kerning(1.5)
                    }

                    Text("Café Portland")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                    Text("Artisan Coffee & Fresh Pastries")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                }
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .frame(width: 46, height: 46)

                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(Color(red: 0.92, green: 0.85, blue: 0.72))
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Hero Image

    private var heroImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.28, green: 0.22, blue: 0.16),
                            Color(red: 0.18, green: 0.14, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 210)
                .overlay(
                    ZStack {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 90))
                            .foregroundColor(.white.opacity(0.06))
                            .offset(x: 60, y: -10)

                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(red: 0.95, green: 0.8, blue: 0.4))
                                    Text("4.9")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("(2.3k)")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                )
                                .padding(14)
                            }
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 6) {
                Text("OPEN NOW")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .kerning(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.35, green: 0.65, blue: 0.35))
                    )

                Text("Order ahead · Pick up in 5 min")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(18)
        }
    }

    // MARK: - Menu

    private var menuSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Popular")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            VStack(spacing: 10) {
                ForEach(menuItems) { item in
                    Button(action: { withAnimation(.spring(response: 0.3)) { selectedItem = item } }) {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(item.color.opacity(0.12))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: item.icon)
                                        .foregroundColor(item.color)
                                        .font(.system(size: 18))
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                                Text(item.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(item.price)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Order

    private var orderSection: some View {
        VStack(spacing: 16) {
            if orderPlaced {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.35, green: 0.65, blue: 0.35).opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.35))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Order Placed!")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        Text("We'll send a notification when it's ready")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    }
                    Spacer()
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
            } else {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { orderPlaced = true }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(selectedItem != nil ? "Order \(selectedItem!.name) · \(selectedItem!.price)" : "Place Order · $4.50")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.2, green: 0.15, blue: 0.1))
                    )
                }
            }

            Button(action: {
                if let url = URL(string: "https://apps.apple.com/app/id123456789") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 13))
                    Text("Get the full app on the App Store")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Push Status

    private var pushStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Notification Status")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                Spacer()

                Button(action: { withAnimation(.spring(response: 0.3)) { showDebug.toggle() } }) {
                    Image(systemName: showDebug ? "chevron.up" : "wrench.and.screwdriver")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                }
            }

            HStack(spacing: 10) {
                statusDot(active: sdkReady)
                Text(sdkReady ? "SDK Ready · Ephemeral Push Active" : "Initializing SDK...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.35, green: 0.3, blue: 0.25))
                Spacer()
            }

            HStack(spacing: 10) {
                statusDot(active: pushToken != nil)
                Text(pushToken != nil ? "Push Token Received" : "Waiting for push token...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.35, green: 0.3, blue: 0.25))
                Spacer()
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Debug

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Debug")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            debugRow(label: "SDK Status", value: sdkReady ? "Ready" : "Initializing")
            debugRow(label: "Push Token", value: pushToken ?? "—")
            debugRow(label: "App Code", value: appCode)
            debugRow(label: "HWID", value: hwid)
            debugRow(label: "Environment", value: "App Clip (Ephemeral 8h)")

            Button(action: { registerForPush() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Re-register")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.3), lineWidth: 1.5)
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Push Banner

    private func pushBannerOverlay(title: String, body: String) -> some View {
        VStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .frame(width: 38, height: 38)
                    Image(systemName: "bell.fill")
                        .foregroundColor(Color(red: 0.92, green: 0.85, blue: 0.72))
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    if !body.isEmpty {
                        Text(body)
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    }
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Helpers

    private func statusDot(active: Bool) -> some View {
        Circle()
            .fill(active ? Color(red: 0.35, green: 0.65, blue: 0.35) : Color(red: 0.75, green: 0.7, blue: 0.65))
            .frame(width: 8, height: 8)
    }

    private func registerForPush() {
        Pushwoosh.configure.registerForPushNotifications { token, error in
            DispatchQueue.main.async {
                sdkReady = true
                if let token = token {
                    pushToken = token
                }
            }
        }
    }

    private var appCode: String {
        (Bundle.main.object(forInfoDictionaryKey: "Pushwoosh_APPID") as? String) ?? "—"
    }

    private var hwid: String {
        (try? Pushwoosh.configure.getHWID()) ?? "—"
    }

    private func debugRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.6, green: 0.55, blue: 0.5))
                .kerning(0.5)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

#Preview {
    RestaurantView()
}
