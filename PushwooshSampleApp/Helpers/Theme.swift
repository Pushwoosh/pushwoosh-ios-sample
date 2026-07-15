//
//  Theme.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI

// PushMart brand design system. Premium dark shopping look: ink background,
// coral -> tangerine accent, crisp white type. All UI in the app draws from
// these tokens so the whole product reads as one coherent brand.
enum PushMart {

    // MARK: Palette
    static let coral       = Color(rgb: 0xFF5A5F)
    static let tangerine   = Color(rgb: 0xFF8A3D)
    static let ink         = Color(rgb: 0x0B0B10)   // base background
    static let ink2        = Color(rgb: 0x14141C)   // elevated background
    static let surface     = Color(rgb: 0x1B1B25)   // card fill
    static let surfaceHi    = Color(rgb: 0x24242F)  // raised card / field
    static let stroke       = Color.white.opacity(0.08)
    static let strokeStrong = Color.white.opacity(0.16)
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.64)
    static let textTertiary  = Color.white.opacity(0.38)
    static let success       = Color(rgb: 0x2BD98A)
    static let warning       = Color(rgb: 0xFFC24B)
    static let danger        = Color(rgb: 0xFF4D5E)

    // MARK: Gradients
    static let brand = LinearGradient(colors: [coral, tangerine],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
    static let brandHorizontal = LinearGradient(colors: [coral, tangerine],
                                                startPoint: .leading, endPoint: .trailing)
    static var backdrop: LinearGradient {
        LinearGradient(colors: [ink2, ink], startPoint: .top, endPoint: .bottom)
    }

    // MARK: Radii / spacing
    static let radiusCard: CGFloat = 22
    static let radiusField: CGFloat = 14
    static let radiusPill: CGFloat = 100

    // MARK: Type
    static func display(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func title(_ size: CGFloat = 22)   -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func headline(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 15)     -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func label(_ size: CGFloat = 12)    -> Font { .system(size: size, weight: .semibold, design: .rounded) }
}

// Module-wide hex initializer. Distinct label (`rgb:`) so it never collides
// with the fileprivate `init(hex:)` extensions in ContentView / LA views.
extension Color {
    init(rgb: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255,
                  opacity: alpha)
    }
}

// MARK: - Screen scaffold

// Standard PushMart screen background. Drop behind any tab content.
struct PushMartBackground: View {
    var body: some View {
        ZStack {
            PushMart.backdrop.ignoresSafeArea()
            Circle()
                .fill(PushMart.coral.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 140)
                .offset(x: 150, y: -300)
                .ignoresSafeArea()
            Circle()
                .fill(PushMart.tangerine.opacity(0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 150)
                .offset(x: -160, y: 360)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Cards

struct PushMartCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous)
                    .fill(PushMart.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous)
                            .strokeBorder(PushMart.stroke, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(PushMart.title(20))
                .foregroundStyle(PushMart.textPrimary)
            Spacer()
            if let action, let onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(PushMart.label(13))
                        .foregroundStyle(PushMart.coral)
                }
            }
        }
    }
}

// MARK: - Buttons

struct PushMartButton: View {
    enum Style { case primary, secondary, ghost }
    let title: String
    var icon: String? = nil
    var style: Style = .primary
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) { pressed = true }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation { pressed = false }
            }
        } label: {
            HStack(spacing: 9) {
                if let icon { Image(systemName: icon).font(.system(size: 15, weight: .bold)) }
                Text(title).font(PushMart.headline(16))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(Capsule())
            .overlay(border)
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .primary:   PushMart.brandHorizontal
        case .secondary: PushMart.surfaceHi
        case .ghost:     Color.clear
        }
    }
    private var foreground: Color {
        switch style {
        case .primary:   return PushMart.ink
        case .secondary: return PushMart.textPrimary
        case .ghost:     return PushMart.coral
        }
    }
    @ViewBuilder private var border: some View {
        if style == .ghost {
            Capsule().strokeBorder(PushMart.coral.opacity(0.5), lineWidth: 1.5)
        } else if style == .secondary {
            Capsule().strokeBorder(PushMart.stroke, lineWidth: 1)
        }
    }
}

// MARK: - Text field

struct PushMartField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PushMart.textTertiary)
            }
            TextField("", text: $text,
                      prompt: Text(placeholder).foregroundColor(PushMart.textTertiary))
                .foregroundStyle(PushMart.textPrimary)
                .font(PushMart.body(15))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous)
                .fill(PushMart.surfaceHi)
                .overlay(
                    RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous)
                        .strokeBorder(PushMart.stroke, lineWidth: 1)
                )
        )
    }
}

// MARK: - Chip

struct PushMartChip: View {
    let title: String
    var selected: Bool = false
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 12, weight: .bold)) }
            Text(title).font(PushMart.label(13))
        }
        .foregroundStyle(selected ? PushMart.ink : PushMart.textSecondary)
        .padding(.horizontal, 15)
        .padding(.vertical, 9)
        .background(
            Group {
                if selected { Capsule().fill(PushMart.brandHorizontal) }
                else { Capsule().fill(PushMart.surfaceHi).overlay(Capsule().strokeBorder(PushMart.stroke, lineWidth: 1)) }
            }
        )
    }
}

// MARK: - Brand wordmark

struct PushMartWordmark: View {
    var size: CGFloat = 26
    var body: some View {
        HStack(spacing: 2) {
            Text("PushMart")
                .font(.system(size: size, weight: .black, design: .rounded))
                .foregroundStyle(PushMart.textPrimary)
            Circle()
                .fill(PushMart.brand)
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(y: size * 0.32)
        }
    }
}

// MARK: - SDK annotation ("spec tag")

// A quiet, always-on caption under a control: the exact Pushwoosh SDK call in
// monospace plus a plain one-line description of what it does. Turns the sample
// into live, self-documenting SDK docs for the team. Attach via `.sdkNote(_:_:)`
// so the element and its note stay left-aligned with consistent spacing.
// One concrete SDK invocation shown in the detail sheet: the exact call + what it does.
struct SDKCallItem: Identifiable {
    var id: String { code }
    let code: String
    let note: String
}

struct SDKNote: View {
    let call: String
    var detail: String? = nil
    var docs: String? = nil
    var calls: [SDKCallItem] = []
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(PushMart.coral.opacity(0.85))
                        Text(call)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(PushMart.textSecondary)
                    }
                    if let detail {
                        Text(detail)
                            .font(PushMart.body(11))
                            .foregroundStyle(PushMart.textTertiary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, 10)
                .overlay(alignment: .leading) {
                    Capsule().fill(PushMart.coral.opacity(0.7)).frame(width: 2)
                }
                Spacer(minLength: 8)
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PushMart.coral.opacity(0.8))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("SDK call \(call). Tap for details.")
        .sheet(isPresented: $showDetail) {
            SDKNoteDetail(call: call, detail: detail, docs: docs, calls: calls)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// Bottom sheet expanding an SDKNote: the call, which SDK surface it lives on,
// what it does, and any extra detail. Shown when a spec-tag is tapped.
struct SDKNoteDetail: View {
    let call: String
    var detail: String?
    var docs: String?
    var calls: [SDKCallItem] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PushMart.ink.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(PushMart.coral)
                        Text("PUSHWOOSH SDK")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(PushMart.textTertiary)
                        Spacer()
                        Text(surface)
                            .font(PushMart.label(11))
                            .foregroundStyle(PushMart.ink)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(PushMart.brandHorizontal))
                    }

                    Text(call)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(PushMart.textPrimary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous)
                                .fill(PushMart.surfaceHi)
                                .overlay(RoundedRectangle(cornerRadius: PushMart.radiusField, style: .continuous)
                                    .strokeBorder(PushMart.stroke, lineWidth: 1))
                        )

                    if let detail { section("What it does", detail) }

                    if !calls.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Calls").font(PushMart.headline(15)).foregroundStyle(PushMart.textPrimary)
                            ForEach(calls) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.code)
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(PushMart.coral)
                                        .textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(item.note)
                                        .font(PushMart.body(13))
                                        .foregroundStyle(PushMart.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(PushMart.surface)
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(PushMart.stroke, lineWidth: 1))
                                )
                            }
                        }
                    }

                    if let docs { section("Details", docs) }
                }
                .padding(20)
                .padding(.top, 8)
            }
        }
    }

    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(PushMart.headline(15)).foregroundStyle(PushMart.textPrimary)
            Text(text).font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var surface: String {
        if call.contains("PWInAppManager") { return "In-App" }
        if call.contains("PWInbox") { return "Inbox" }
        if call.contains(".media") || call.contains("RichMedia") { return "Rich media" }
        if call.contains("LiveActivities") { return "Live Activities" }
        if call.contains("ForegroundPush") { return "Foreground push" }
        if call.contains("VoIP") { return "VoIP" }
        if call.contains(".debug") { return "Debug" }
        if call.contains("InboxKit") || call.contains("inboxKit") { return "Inbox UI" }
        if call.contains("PWTagsBuilder") { return "Tags" }
        return "Core"
    }
}

extension View {
    /// Attaches an SDK spec-tag directly under the element, left-aligned. Tapping it
    /// opens a bottom sheet with the call, its SDK surface, and `docs`.
    func sdkNote(_ call: String, _ detail: String? = nil, docs: String? = nil, calls: [SDKCallItem] = []) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            self
            SDKNote(call: call, detail: detail, docs: docs, calls: calls)
        }
    }
}
