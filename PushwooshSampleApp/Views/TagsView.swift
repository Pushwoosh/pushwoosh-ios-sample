//
//  TagsView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework

struct TagsView: View {
    @State private var tagKey: String = ""
    @State private var tagValue: String = ""
    @State private var showSetTagsAlert = false
    @State private var showLoadTagsAlert = false
    @State private var loadedTags: [AnyHashable: Any] = [:]
    @State private var errorMessage: String = ""

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
                            Text("TAGS")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Manage User Tags")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Set Tags Card
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
                                ModernTextField(placeholder: "KEY", text: $tagKey)
                                ModernTextField(placeholder: "VALUE", text: $tagValue)
                            }

                            ModernButton(
                                title: "Set Tags",
                                icon: "checkmark.circle.fill",
                                gradient: [.purple, .pink]
                            ) {
                                Pushwoosh.configure.setTags([tagKey: tagValue])
                                showSetTagsAlert = true
                            }
                            .alert(isPresented: $showSetTagsAlert) {
                                Alert(
                                    title: Text("SET TAGS"),
                                    message: Text("TAGS: key = \(tagKey), value = \(tagValue)"),
                                    dismissButton: .default(Text("OK"))
                                )
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Set custom tags to segment users and personalize notifications. Tags are key-value pairs that can be used for targeting.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Load Tags Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("Load Tags")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            ModernButton(
                                title: "Load Current Tags",
                                icon: "arrow.down.to.line.circle.fill",
                                gradient: [.cyan, .blue]
                            ) {
                                Pushwoosh.configure.loadTags(
                                    { tags in
                                        loadedTags = tags ?? [:]
                                        errorMessage = ""
                                        showLoadTagsAlert = true
                                    },
                                    error: { error in
                                        errorMessage = error?.localizedDescription ?? "Unknown error"
                                        loadedTags = [:]
                                        showLoadTagsAlert = true
                                    }
                                )
                            }
                            .alert(isPresented: $showLoadTagsAlert) {
                                Alert(
                                    title: Text("LOADED TAGS"),
                                    message: Text(errorMessage.isEmpty ? formatTags(loadedTags) : "Error: \(errorMessage)"),
                                    dismissButton: .default(Text("OK"))
                                )
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            Text("Load all tags currently associated with this device from the Pushwoosh server.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(4)
                        }
                    }

                    // Tag Examples Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Example Tags")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                TagExampleRow(key: "Name", value: "John Doe", color: .blue)
                                TagExampleRow(key: "Age", value: "25", color: .green)
                                TagExampleRow(key: "Premium", value: "true", color: .orange)
                                TagExampleRow(key: "City", value: "New York", color: .purple)
                            }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
            }
        }
    }

    private func formatTags(_ tags: [AnyHashable: Any]) -> String {
        guard !tags.isEmpty else {
            return "No tags set"
        }
        var result = ""
        for (key, value) in tags {
            result += "\(key): \(value)\n"
        }
        return result
    }
}

struct TagExampleRow: View {
    let key: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(key)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            Text(":")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TagsView()
}
