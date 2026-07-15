//
//  ResultPresenter.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI

// Shared success / failure feedback shown after any "set" action in the sample.
// Call PushMartResult.shared.success(...) / .fail(...) right after the SDK setter;
// the overlay (attached once at the app root) animates a card in and auto-dismisses.
// Suppressed under UI_TESTING so it never blocks the automated suite.
final class PushMartResult: ObservableObject {
    static let shared = PushMartResult()

    enum Kind { case success, failure }

    @Published var isShowing = false
    @Published private(set) var kind: Kind = .success
    @Published private(set) var title = ""
    @Published private(set) var message = ""

    private var dismissItem: DispatchWorkItem?

    func success(_ title: String, _ message: String = "") { present(.success, title, message) }
    func fail(_ title: String, _ message: String = "") { present(.failure, title, message) }

    func dismiss() {
        dismissItem?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { isShowing = false }
    }

    private func present(_ kind: Kind, _ title: String, _ message: String) {
        guard !PushwooshHelper.isUITesting else { return }
        self.kind = kind
        self.title = title
        self.message = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isShowing = true }

        dismissItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.dismiss() }
        dismissItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
    }
}

private struct PushMartResultOverlay: ViewModifier {
    @ObservedObject private var presenter = PushMartResult.shared
    @State private var pop = false

    func body(content: Content) -> some View {
        content.overlay {
            if presenter.isShowing {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea()
                        .onTapGesture { presenter.dismiss() }
                    card
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }

    private var isSuccess: Bool { presenter.kind == .success }
    private var accent: Color { isSuccess ? PushMart.success : PushMart.danger }

    private var card: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(accent.opacity(0.16)).frame(width: 88, height: 88)
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(accent)
                    .scaleEffect(pop ? 1 : 0.5)
                    .opacity(pop ? 1 : 0)
            }
            Text(presenter.title)
                .font(PushMart.title(21)).foregroundStyle(PushMart.textPrimary)
                .multilineTextAlignment(.center)
            if !presenter.message.isEmpty {
                Text(presenter.message)
                    .font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(28)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(PushMart.ink2)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 30, y: 16)
        )
        .scaleEffect(pop ? 1 : 0.85)
        .onAppear {
            pop = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.05)) { pop = true }
        }
        .onDisappear { pop = false }
    }
}

extension View {
    func pushMartResultOverlay() -> some View { modifier(PushMartResultOverlay()) }
}
