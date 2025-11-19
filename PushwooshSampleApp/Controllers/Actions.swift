//
//  Actions.swift
//  newdemo
//
//  Created by Andrew Kis on 12.4.24..
//

import Foundation
import SwiftUI
import PushwooshFramework

struct Actions: View {
    @State private var textInputKey: String = ""
    @State private var textInputValue: String = ""
    @State private var textInputUser: String = ""
    @State private var textInputEventName: String = ""
    @State private var attributesEnabled = false
    @State private var alertEnabled = true
    @State private var textInputEmail: String = ""
    @State private var textInputLanguage: String = ""
    @State private var showAlert = false
    @State private var showAlertAppCode = false
    @State private var showPushToken = false
    @State private var showHwid = false
    @State private var showUserId = false

    var body: some View {
        let pushToken = Pushwoosh.configure.getPushToken()
        let hwid = Pushwoosh.configure.getHWID()
        let userId = Pushwoosh.configure.getUserId()

        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.2, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PUSHWOOSH")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Demo Application")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Tags Section
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.purple)
                                Text("Set Tags")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            HStack(spacing: 12) {
                                ModernTextField(placeholder: "KEY", text: $textInputKey)
                                ModernTextField(placeholder: "VALUE", text: $textInputValue)
                            }

                            ModernButton(
                                title: "Set Tags",
                                icon: "checkmark.circle.fill",
                                gradient: [.purple, .pink]
                            ) {
                                Pushwoosh.configure.setTags([textInputKey: textInputValue])
                                showAlert = true
                            }
                            .alert(isPresented: $showAlert) {
                                alert(title: "SET TAGS",
                                      message: "TAGS: key = \(textInputKey), value = \(textInputValue)")
                            }
                        }
                    }

                    // User Section
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                Text("User Management")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "USER ID", text: $textInputUser)

                            ModernButton(
                                title: "Register User",
                                icon: "person.badge.plus.fill",
                                gradient: [.blue, .cyan]
                            ) {
                                Pushwoosh.configure.setUserId(textInputUser)
                            }
                        }
                    }

                    // Events Section
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundColor(.orange)
                                Text("Events")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "EVENT NAME", text: $textInputEventName)

                            HStack {
                                Text("With Attributes")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Toggle("", isOn: $attributesEnabled)
                                    .tint(.orange)
                            }

                            ModernButton(
                                title: "Post Event",
                                icon: "calendar.badge.plus",
                                gradient: [.orange, .red]
                            ) {
                                if attributesEnabled {
                                    PWInAppManager.shared().postEvent(textInputEventName, withAttributes: ["Key1": "Value1", "Key2": "Value2"])
                                } else {
                                    PWInAppManager.shared().postEvent(textInputEventName)
                                }
                            }
                        }
                    }

                    // Email & Language Section
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.green)
                                Text("Contact Info")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "EMAIL", text: $textInputEmail)

                            ModernButton(
                                title: "Register Email",
                                icon: "envelope.badge.fill",
                                gradient: [.green, .mint]
                            ) {
                                Pushwoosh.configure.setEmail(textInputEmail)
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            ModernTextField(placeholder: "LANGUAGE (e.g., 'en')", text: $textInputLanguage)

                            ModernButton(
                                title: "Set Language",
                                icon: "globe",
                                gradient: [.teal, .blue]
                            ) {
                                Pushwoosh.configure.setLanguage(textInputLanguage)
                            }
                        }
                    }

                    // Info Section
                    ModernCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("Device Info")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            InfoButton(
                                title: "Push Token",
                                icon: "key.fill",
                                color: .cyan
                            ) {
                                showPushToken = true
                            }
                            .alert(isPresented: $showPushToken) {
                                alert(title: "PUSH TOKEN", message: "\(pushToken ?? "Push Token doesn't exist")")
                            }

                            InfoButton(
                                title: "HWID",
                                icon: "desktopcomputer",
                                color: .blue
                            ) {
                                showHwid = true
                            }
                            .alert(isPresented: $showHwid) {
                                alert(title: "HWID", message: "\(hwid)")
                            }

                            InfoButton(
                                title: "User ID",
                                icon: "person.text.rectangle",
                                color: .purple
                            ) {
                                showUserId = true
                            }
                            .alert(isPresented: $showUserId) {
                                alert(title: "USER ID", message: "\(userId)")
                            }

                            InfoButton(
                                title: "App Code",
                                icon: "qrcode",
                                color: .pink
                            ) {
                                showAlertAppCode = true
                            }
                            .alert(isPresented: $showAlertAppCode) {
                                alert(title: "APPLICATION CODE", message: "\(Pushwoosh.configure.getApplicationCode() ?? "Not set")")
                            }
                        }
                    }

                    // Actions Section
                    ModernCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "bolt.circle.fill")
                                    .foregroundColor(.yellow)
                                Text("Actions")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernButton(
                                title: "Send Local Notification",
                                icon: "bell.badge.fill",
                                gradient: [.indigo, .purple]
                            ) {
                                Notifications.shared.showLocalNotification(title: "Hello", body: "Pushwoosh")
                            }

                            ModernButton(
                                title: "Clear Notifications",
                                icon: "bell.slash.fill",
                                gradient: [.gray, .secondary]
                            ) {
                                PushNotificationManager.clearNotificationCenter()
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            ModernButton(
                                title: "Stop Communication",
                                icon: "stop.circle.fill",
                                gradient: [.red, .orange]
                            ) {
                                Pushwoosh.configure.stopServerCommunication()
                            }

                            ModernButton(
                                title: "Start Communication",
                                icon: "play.circle.fill",
                                gradient: [.green, .mint]
                            ) {
                                Pushwoosh.configure.startServerCommunication()
                            }
                        }
                    }

                    // Settings Card
                    ModernCard {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("Show Alert")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $alertEnabled)
                                .tint(.yellow)
                                .onChange(of: alertEnabled) { oldValue, newValue in
                                    Pushwoosh.configure.setShowPushnotificationAlert(newValue)
                                }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
            }
        }
    }

    func alert(title: String, message: String) -> Alert {
        return Alert(
            title: Text("\(title)"),
            message: Text("\(message)"),
            dismissButton: .default(Text("OK"))
        )
    }
}

// MARK: - Modern Components

struct ModernCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct ModernButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .shadow(color: gradient[0].opacity(0.5), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 2 : 5)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}

struct InfoButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
}

struct ModernTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

#Preview {
    Actions()
}
