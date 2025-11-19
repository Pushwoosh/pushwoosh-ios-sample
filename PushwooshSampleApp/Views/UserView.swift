//
//  UserView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework

struct UserView: View {
    @State private var userId: String = ""
    @State private var email: String = ""
    @State private var showUserIdAlert = false
    @State private var currentUserId: String = ""

    private func logSDKCall(_ method: String, params: String? = nil, result: String? = nil) {
        #if DEBUG
        SDKCallLogger.shared.log(method, params: params, result: result)
        #endif
    }

    var body: some View {
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
                            Text("USER")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Manage User Identity")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Set User ID Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "person.badge.plus.fill")
                                    .foregroundColor(.blue)
                                Text("Set User ID")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "USER ID", text: $userId)
                                .accessibilityIdentifier("userIdTextField")

                            ModernButton(
                                title: "Set User ID",
                                icon: "checkmark.circle.fill",
                                gradient: [.blue, .cyan]
                            ) {
                                Pushwoosh.configure.setUserId(userId)
                                logSDKCall("Pushwoosh.configure.setUserId(_:)",
                                         params: "userId: \"\(userId)\"",
                                         result: "User ID set successfully")
                            }
                        }
                    }

                    // Set Email Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.green)
                                Text("Set Email")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernTextField(placeholder: "EMAIL", text: $email)

                            ModernButton(
                                title: "Set Email",
                                icon: "envelope.badge.fill",
                                gradient: [.green, .mint]
                            ) {
                                logSDKCall("Pushwoosh.configure.setEmail(_:)", params: "email: \"\(email)\"")
                                Pushwoosh.configure.setEmail(email)
                            }
                        }
                    }

                    // Get User ID Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .foregroundColor(.purple)
                                Text("Get User ID")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernButton(
                                title: "Get Current User ID",
                                icon: "arrow.down.circle.fill",
                                gradient: [.purple, .pink]
                            ) {
                                let result = Pushwoosh.configure.getUserId()
                                logSDKCall("Pushwoosh.configure.getUserId()", result: "userId: \"\(result)\"")
                                currentUserId = result
                                showUserIdAlert = true
                            }
                            .alert(isPresented: $showUserIdAlert) {
                                Alert(
                                    title: Text("USER ID"),
                                    message: Text(currentUserId.isEmpty ? "No User ID set" : currentUserId),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    UserView()
}
