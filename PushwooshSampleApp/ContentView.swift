//
//  ContentView.swift
//  PushwooshSampleApp
//

import SwiftUI

struct ContentView: View {
    @State private var isMenuShowing = false
    @State private var selectedCategory: MenuCategory = .user

    var body: some View {
        ZStack {
            // Background for entire app
            Color(red: 0.1, green: 0.1, blue: 0.2)
                .ignoresSafeArea(.all)

            // Main content with menu button
            VStack(spacing: 0) {
                // Top bar with menu button
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isMenuShowing = true
                        }
                    }) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .semibold))
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)

                // Category content
                CategoryContentView(selectedCategory: selectedCategory)

                // SDK Call Log at bottom (visible in DEBUG builds)
                #if DEBUG
                SDKCallLogView()
                #endif
            }

            // Side menu overlay
            SideMenu(
                isShowing: $isMenuShowing,
                selectedCategory: $selectedCategory
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CategoryContentView: View {
    let selectedCategory: MenuCategory

    var body: some View {
        Group {
            switch selectedCategory {
            case .user:
                UserView()
            case .registration:
                RegistrationView()
            case .tags:
                TagsView()
            case .device:
                DeviceInfoView()
            case .communication:
                CommunicationView()
            case .settings:
                SettingsView()
            case .monetization:
                MonetizationView()
            case .liveActivities:
                LiveActivitiesView()
            case .notifications:
                NotificationsView()
            // case .debugLogs:
            //     DebugLogsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
