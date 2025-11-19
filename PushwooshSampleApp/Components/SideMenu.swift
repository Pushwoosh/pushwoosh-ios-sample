//
//  SideMenu.swift
//  PushwooshSampleApp
//

import SwiftUI

struct SideMenu: View {
    @Binding var isShowing: Bool
    @Binding var selectedCategory: MenuCategory

    var body: some View {
        ZStack {
            if isShowing {
                // Dimmed background
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isShowing = false
                        }
                    }

                // Menu content
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
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

                                Spacer()

                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isShowing = false
                                    }
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 36, height: 36)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }

                            Text("PUSHWOOSH SDK")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.white)

                            Text("Explore SDK Methods")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        .padding(.bottom, 30)

                        // Menu items
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 4) {
                                ForEach(MenuCategory.allCases) { category in
                                    MenuButton(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedCategory = category
                                            isShowing = false
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer()

                        // Footer
                        VStack(spacing: 12) {
                            Divider()
                                .background(Color.white.opacity(0.2))

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Version 1.0.0")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))

                                    Text("Pushwoosh SDK Demo")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 30)
                        }
                    }
                    .frame(width: 280)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.2),
                                Color(red: 0.15, green: 0.1, blue: 0.25),
                                Color(red: 0.1, green: 0.15, blue: 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 5, y: 0)

                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowing)
    }
}

struct MenuButton: View {
    let category: MenuCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? category.color : .white.opacity(0.7))
                    .frame(width: 28)

                Text(category.rawValue)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))

                Spacer()

                if isSelected {
                    Circle()
                        .fill(category.color)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SideMenu(
        isShowing: .constant(true),
        selectedCategory: .constant(.user)
    )
}
