//
//  InboxKitView.swift
//  PushwooshSampleApp
//
//  Inbox tab. A two-row chooser (Default / Custom) pushes into a full-screen
//  InboxDetailView so the offers feed gets the whole screen instead of sharing
//  it with a header and a pill row. "Default" builds the feed with the SDK's
//  built-in cells; "Custom" swaps the captioned slot for a host-owned
//  PromoCaptionedCell — no `forceCellKind`; every row's type is still decided
//  server-side via `actionParams["displayType"]`, mirroring Braze Content Cards.
//
//  InboxDetailView wraps the SDK's PushwooshInboxKitViewController (nav bar
//  hidden, chrome recolored on-brand via the appearance setters), a branded
//  header with the live unread badge and the ⋯ bulk-actions menu, and a custom
//  empty-state overlay shown only on confirmed-empty refreshes (errors keep the
//  feed visible to avoid flicker).
//

import SwiftUI
import UIKit
import PushwooshFramework
import PushwooshInboxKit

struct InboxKitView: View {
    // Live unread count drives the "N new" pill in the chooser header.
    @StateObject private var unread = InboxUnreadModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    intro
                    chooser
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 96)
            }
            .background(PushMartBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Inbox").font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                }
            }
        }
        .tint(PushMart.coral)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Your offers").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
                if unread.count > 0 {
                    Text("\(unread.count) new")
                        .font(PushMart.label(12))
                        .foregroundStyle(PushMart.ink)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(PushMart.brandHorizontal))
                        .accessibilityLabel("\(unread.count) unread offers")
                }
            }
            Text("Open the feed with the SDK's built-in cells, or with your own custom cell.")
                .font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private var chooser: some View {
        VStack(spacing: 0) {
            NavigationLink {
                InboxDetailView(styled: false, title: "Default offers")
            } label: {
                InboxChooserRow(icon: "tray.full.fill", tint: 0xFF5A5F,
                                title: "Default offers",
                                subtitle: "InboxKit feed with the SDK's built-in cells")
            }
            .accessibilityIdentifier("inbox.defaultOffers")

            Divider().overlay(PushMart.stroke).padding(.leading, 68)

            NavigationLink {
                InboxDetailView(styled: true, title: "Custom offers")
            } label: {
                InboxChooserRow(icon: "sparkles", tint: 0xAF7BFF,
                                title: "Custom offers",
                                subtitle: "Same feed, host PromoCaptionedCell + brand appearance")
            }
            .accessibilityIdentifier("inbox.styleToggle")
        }
        .background(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).fill(PushMart.surface)
            .overlay(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
        .sdkNote(
            "PushwooshInboxKitViewController(attributes:)",
            "Each row opens the same InboxKit feed built with a different cell registry.",
            docs: "Every row's type is still decided server-side via actionParams[\"displayType\"], mirroring Braze Content Cards. applyAppearance recolors the feed on-brand through the InboxKit appearance API: setAccentColor, setBackgroundColor, setSeparatorColor and more, plus setEmptyMessage / setErrorMessage for the empty and error states.",
            calls: [
                SDKCallItem(code: "PushwooshInboxKitViewController(attributes: attrs)", note: "Default offers - the embedded feed with the SDK's built-in cells."),
                SDKCallItem(code: "attrs.cells[\"captioned\"] = PromoCaptionedCell.self", note: "Custom offers - swaps the captioned cell for the host's PromoCaptionedCell.")
            ]
        )
    }
}

// MARK: - Chooser row

/// A single tappable row in the Inbox chooser, styled like the Profile rows.
struct InboxChooserRow: View {
    let icon: String
    let tint: UInt32
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color(rgb: tint))
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color(rgb: tint).opacity(0.16)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                Text(subtitle).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(PushMart.textTertiary)
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}

// MARK: - Full-screen inbox

/// The offers feed on its own full screen, reached from the Inbox chooser.
/// `styled` decides whether the captioned slot uses the host's
/// PromoCaptionedCell. Dedicating the whole screen to the feed - no pill row,
/// no chooser chrome - is the point of the chooser split.
struct InboxDetailView: View {
    let styled: Bool
    var title: String = "Your offers"

    @StateObject private var unread = InboxUnreadModel()
    @StateObject private var controller = OffersController()

    var body: some View {
        ZStack {
            PushMartBackground()

            VStack(spacing: 0) {
                header
                OffersFeed(styled: styled, controller: controller)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { bulkMenu }
        }
    }

    // Slim strip: live unread line + the always-on SDK caption, so the feed
    // keeps the whole screen below it. Bulk actions live in the nav-bar ⋯ menu.
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            unreadInline
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sdkNote(
            "PushwooshInboxKitViewController bulk actions",
            "The nav-bar ⋯ menu runs bulk actions across the whole offers feed.",
            docs: "The live unread line reads from InboxUnreadModel, which calls PWInbox.unreadMessagesCount for the current total and PWInbox.addObserverForUnreadMessagesCount to keep it live as offers are read or arrive.",
            calls: [
                SDKCallItem(code: "vc.markAllAsRead()", note: "Marks every offer in the feed as read."),
                SDKCallItem(code: "vc.deleteAllMessages()", note: "Removes all offers from the inbox."),
                SDKCallItem(code: "vc.reloadData()", note: "Refreshes the feed from the local cache."),
                SDKCallItem(code: "try await vc.reload()", note: "Async refresh that fetches the latest offers from the server."),
                SDKCallItem(code: "vc.clearReadMessages()", note: "Drops only the offers that have already been read.")
            ]
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    @ViewBuilder private var unreadInline: some View {
        if unread.count > 0 {
            HStack(spacing: 6) {
                Circle().fill(PushMart.coral).frame(width: 7, height: 7)
                Text("\(unread.count) new")
                    .font(PushMart.label(12))
                    .foregroundStyle(PushMart.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(unread.count) unread offers")
        } else {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("All caught up")
                    .font(PushMart.label(12))
            }
            .foregroundStyle(PushMart.textSecondary)
        }
    }

    private var bulkMenu: some View {
        Menu {
            Button { controller.markAllRead() } label: { Label("Mark all read", systemImage: "checkmark.circle") }
            Button { controller.reload() } label: { Label("Reload", systemImage: "arrow.clockwise") }
            Button { controller.reloadAsync() } label: { Label("Reload (async)", systemImage: "arrow.triangle.2.circlepath") }
            Button { controller.clearRead() } label: { Label("Clear read", systemImage: "checkmark.circle.badge.xmark") }
            Divider()
            Button(role: .destructive) { controller.deleteAll() } label: { Label("Delete all", systemImage: "trash") }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18, weight: .semibold))
        }
        .accessibilityIdentifier("inbox.more")
    }
}

// MARK: - Feed proxy

/// Thin bridge between the SwiftUI header's ⋯ menu and the live inbox VC.
/// Holds a weak ref so a torn-down feed doesn't keep the controller alive.
final class OffersController: ObservableObject {
    weak var vc: PushwooshInboxKitViewController?

    func markAllRead() { vc?.markAllAsRead() }
    func deleteAll()   { vc?.deleteAllMessages() }
    func reload()      { vc?.reloadData() }
    func reloadAsync() { Task { try? await vc?.reload() } }
    func clearRead()   { vc?.clearReadMessages() }
}

// MARK: - Feed

/// Wraps a single `PushwooshInboxKitViewController`. `styled` decides whether
/// the captioned slot points at the host's `PromoCaptionedCell`; the host
/// flips it by rebuilding this representable via `.id(styled)`. Banner and
/// classic always stay on the SDK defaults — only the captioned cell changes.
struct OffersFeed: UIViewControllerRepresentable {
    let styled: Bool
    let controller: OffersController

    func makeUIViewController(context: Context) -> UINavigationController {
        let coord = context.coordinator

        var attrs = PushwooshInboxKitAttributes()
        // A message is marked read only when the user actually opens it — never
        // just because it was visible when the inbox left the screen.
        attrs.automaticReadOnDisappear = false
        // iOS 26 Liquid Glass cards (opt-in; solid cards on earlier OSes).
        attrs.style.isLiquidGlass = true
        if styled {
            // Swap just the captioned slot; the rest keep the SDK defaults.
            attrs.cells["captioned"] = PromoCaptionedCell.self
        }

        let vc = PushwooshInboxKitViewController(attributes: attrs)
        vc.delegate = coord
        coord.host = vc
        controller.vc = vc
        applyAppearance(to: vc)

        let empty = EmptyInboxView()
        empty.onRefresh = { [weak vc] in vc?.reloadData() }
        coord.emptyOverlay = empty
        empty.translatesAutoresizingMaskIntoConstraints = false
        empty.isHidden = true
        empty.alpha = 0
        vc.view.addSubview(empty)
        NSLayoutConstraint.activate([
            empty.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            empty.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            empty.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor),
            empty.bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor)
        ])

        let nav = UINavigationController(rootViewController: vc)
        nav.overrideUserInterfaceStyle = .dark
        nav.setNavigationBarHidden(true, animated: false)
        nav.isNavigationBarHidden = true
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> InboxModalCoordinator { InboxModalCoordinator() }

    // Exercises the InboxKit appearance API, fully on the PushMart palette.
    // These are UIKit `UIColor`s (not SwiftUI `Color`s), so the hex brand
    // tokens are written as `UIColor(red:green:blue:alpha:)` literals.
    private func applyAppearance(to vc: PushwooshInboxKitViewController) {
        let ink   = UIColor(red: CGFloat(0x0B) / 255, green: CGFloat(0x0B) / 255, blue: CGFloat(0x10) / 255, alpha: 1)
        let coral = UIColor(red: CGFloat(0xFF) / 255, green: CGFloat(0x5A) / 255, blue: CGFloat(0x5F) / 255, alpha: 1)

        vc.setBackgroundColor(ink)
        vc.setAccentColor(coral)
        vc.setSeparatorColor(UIColor(white: 1, alpha: 0.08))
        vc.setEmptyMessage("No offers yet")
        vc.setEmptyImage(UIImage(systemName: "gift"))
        vc.setErrorMessage("Couldn't load offers")
        vc.setErrorImage(UIImage(systemName: "exclamationmark.triangle"))
        vc.setDateFormatter { date in
            let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
            return f.string(from: date)
        }
        vc.setSwipeToDeleteEnabled(true)
        vc.setEnableDarkTheme(true)
        vc.setPinningEnabled(true)
        vc.setPinIndicatorVisible(true)
        vc.setPinIndicatorColor(coral)
        vc.setInlineButtonsEnabled(true)
        vc.setButtonBackgroundColor(coral)
        vc.setButtonTextColor(.white)
        vc.setButtonFont(.systemFont(ofSize: 14, weight: .semibold))
        // Read back the live attributes (the `attributes` getter).
        print("[Inbox] liquid glass: \(vc.attributes.style.isLiquidGlass)")
    }
}

// MARK: - Custom-action tags
//
// One per known business action the marketer can attach to a `.custom` button
// via Custom Data: `"action": "custom", "tag": "save"`. Compile-time exhaustive
// switch means typos in the JSON show up immediately when the integrator runs
// the app, instead of silently no-op'ing in production.

enum SampleInboxAction: String {
    case save
    case snooze
    case share
}

// MARK: - Coordinator

final class InboxModalCoordinator: NSObject, PushwooshInboxKitDelegate {
    weak var host: UIViewController?
    weak var emptyOverlay: EmptyInboxView?

    // MARK: - Wallet add result (success / error)

    func inboxKit(_ vc: PushwooshInboxKitViewController, didAddWalletPassFor message: PWInboxMessageProtocol) {
        print("[Inbox][Wallet] ✅ pass added — code=\(message.code ?? "?") title=\(message.title ?? "")")
        presentWalletSuccess(passTitle: message.title ?? "Your pass")
    }

    func inboxKit(_ vc: PushwooshInboxKitViewController, didFailToAddWalletPassFor message: PWInboxMessageProtocol, error: Error?) {
        print("[Inbox][Wallet] ❌ add failed — code=\(message.code ?? "?") error=\(error?.localizedDescription ?? "nil")")
    }

    private func presentWalletSuccess(passTitle: String, attempt: Int = 0) {
        // Bail if the inbox left the screen during the retry window — don't present on a detached VC.
        guard let presenter = host, presenter.viewIfLoaded?.window != nil, attempt < 12 else { return }
        // The system add-passes sheet is still dismissing right after the callback fires; presenting
        // mid-transition is silently dropped. Wait until the presenter is free, then present.
        if presenter.presentedViewController != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.presentWalletSuccess(passTitle: passTitle, attempt: attempt + 1)
            }
            return
        }
        let successVC = UIHostingController(rootView: WalletAddedView(passTitle: passTitle))
        successVC.modalPresentationStyle = .pageSheet
        if #available(iOS 16.0, *) {
            successVC.sheetPresentationController?.detents = [.medium()]
            successVC.sheetPresentationController?.prefersGrabberVisible = true
            successVC.sheetPresentationController?.preferredCornerRadius = 28
        }
        presenter.present(successVC, animated: true)
    }

    func inboxKit(_ vc: PushwooshInboxKitViewController,
                  didRefreshWith messages: [PWInboxMessageProtocol],
                  error: Error?) {
        if error == nil && messages.isEmpty {
            showOverlay(emptyOverlay)
        } else {
            hideOverlay(emptyOverlay)
        }
    }

    func inboxKit(_ vc: PushwooshInboxKitViewController, willDisplay message: PWInboxMessageProtocol, at indexPath: IndexPath) {
        print("[Inbox] will display row \(indexPath.row): \(message.title ?? "")")
    }

    func inboxKit(_ vc: PushwooshInboxKitViewController, shouldDelete message: PWInboxMessageProtocol) -> Bool {
        print("[Inbox] shouldDelete \(message.code ?? "?")")
        return true
    }

    func inboxKit(didDismiss vc: PushwooshInboxKitViewController) {
        print("[Inbox] dismissed")
    }

    func inboxKit(_ vc: PushwooshInboxKitViewController,
                  didSelect message: PWInboxMessageProtocol) -> Bool {
        let alert = UIAlertController(
            title: message.title ?? "Tapped",
            message: "code: \(message.code ?? "?")\nbody: \(message.message ?? "")",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
        // We're skipping the SDK default (return false) so the URL/richmedia
        // doesn't open, but we still want the row to flip to read state.
        vc.markRead(messages: [message])
        return false
    }

    /// Inline CTA button tap.
    ///
    /// One callback fires for every button on every card — the host
    /// differentiates them via `button.action` (typed enum) and, for
    /// `.custom`, via `payload["tag"]` agreed with the marketer.
    ///
    /// Return `true` to let the SDK do its default (open URL, dismiss,
    /// mark read). Return `false` when the host fully owned the action.
    func inboxKit(_ vc: PushwooshInboxKitViewController,
                  didTapButton button: PushwooshInboxButton,
                  onMessage message: PWInboxMessageProtocol) -> Bool {
        switch button.action {
        case .openURL(let url):
            // Built-in: SDK will open the URL after we return true.
            // Common practice — log analytics here, then let the SDK do the rest.
            showAlert(on: vc,
                      title: "Open URL",
                      body: "\(button.title)\n\nWill open: \(url.absoluteString)")
            return true

        case .markRead:
            // Built-in: SDK will mark the message read after we return true.
            showAlert(on: vc,
                      title: "Mark as read",
                      body: "\(button.title)")
            return true

        case .dismiss:
            // Built-in: SDK will delete the message after we return true.
            showAlert(on: vc,
                      title: "Dismiss",
                      body: "\(button.title) — message will be removed")
            return true

        case .custom(let payload):
            return handleCustomButton(button, payload: payload, on: message, vc: vc)
        }
    }

    /// Custom-action dispatcher. Maps `payload["tag"]` to a typed enum so
    /// switching is exhaustive and tag typos are caught at compile time.
    private func handleCustomButton(_ button: PushwooshInboxButton,
                                    payload: [String: Any],
                                    on message: PWInboxMessageProtocol,
                                    vc: PushwooshInboxKitViewController) -> Bool {
        guard let raw = payload["tag"] as? String,
              let tag = SampleInboxAction(rawValue: raw) else {
            // Unknown tag — show what we got so the integrator can debug
            // their dashboard payload, then let the SDK do its (no-op) default.
            showAlert(on: vc,
                      title: "Custom (unknown tag)",
                      body: "title: \(button.title)\npayload: \(payload)")
            return false
        }

        switch tag {
        case .save:
            let sku = payload["sku"] as? String ?? "—"
            showAlert(on: vc,
                      title: "Save to favorites",
                      body: "\(button.title)\n\nsku: \(sku)\n(host would persist this)")

        case .snooze:
            let seconds = payload["seconds"] as? Int ?? 60
            scheduleSnoozeAlert(after: seconds, message: message)
            showAlert(on: vc,
                      title: "Snooze scheduled",
                      body: "\(button.title)\n\nAlert will appear in \(seconds)s")

        case .share:
            let text = payload["text"] as? String ?? message.title ?? ""
            showAlert(on: vc,
                      title: "Share",
                      body: "\(button.title)\n\nWould share: \(text)")
        }
        return false   // we fully owned the side-effect
    }

    private func showAlert(on vc: UIViewController, title: String, body: String) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }

    /// Schedules an in-app reminder alert after `seconds`. The alert echoes
    /// the inbox message's title/body so the user sees the same content
    /// again as a reminder. The alert is shown on whichever view controller
    /// is topmost at fire time (covers cases where the inbox sheet was
    /// dismissed before the timer fires).
    private func scheduleSnoozeAlert(after seconds: Int, message: PWInboxMessageProtocol) {
        let title = message.title ?? "Reminder"
        let body = message.message ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(max(seconds, 1))) { [weak self] in
            guard let topVC = self?.topPresentedViewController() else { return }
            self?.showAlert(on: topVC,
                            title: "⏰ \(title)",
                            body: body)
        }
    }

    /// Walks the presented-view-controller chain to find the topmost VC so
    /// the snooze alert always lands on whatever is currently visible.
    private func topPresentedViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let keyWindow = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    private func showOverlay(_ overlay: UIView?) {
        guard let overlay = overlay, overlay.isHidden else { return }
        overlay.isHidden = false
        UIView.animate(withDuration: 0.30, delay: 0, options: [.curveEaseOut]) {
            overlay.alpha = 1
        }
    }

    private func hideOverlay(_ overlay: UIView?) {
        guard let overlay = overlay, !overlay.isHidden else { return }
        UIView.animate(withDuration: 0.20, animations: {
            overlay.alpha = 0
        }, completion: { _ in
            overlay.isHidden = true
        })
    }
}

// MARK: - Empty state (UIKit, on-brand)

final class EmptyInboxView: UIView {

    var onRefresh: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let ink   = UIColor(red: CGFloat(0x0B) / 255, green: CGFloat(0x0B) / 255, blue: CGFloat(0x10) / 255, alpha: 1)
        let coral = UIColor(red: CGFloat(0xFF) / 255, green: CGFloat(0x5A) / 255, blue: CGFloat(0x5F) / 255, alpha: 1)
        backgroundColor = ink

        let halo = UIView()
        halo.translatesAutoresizingMaskIntoConstraints = false
        halo.backgroundColor = coral.withAlphaComponent(0.14)
        halo.layer.cornerRadius = 64
        addSubview(halo)

        let glyph = UIImageView()
        glyph.translatesAutoresizingMaskIntoConstraints = false
        glyph.contentMode = .scaleAspectFit
        let cfg = UIImage.SymbolConfiguration(pointSize: 52, weight: .semibold)
        glyph.image = UIImage(systemName: "gift.fill", withConfiguration: cfg)
        glyph.tintColor = coral
        addSubview(glyph)

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "No offers yet"
        title.font = EmptyInboxView.roundedFont(23, .heavy)
        title.textColor = .white
        title.textAlignment = .center
        addSubview(title)

        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.text = "Deals and rewards you unlock will land right here. Pull to refresh or tap below."
        subtitle.font = EmptyInboxView.roundedFont(14, .regular)
        subtitle.textColor = UIColor(white: 1, alpha: 0.64)
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .center
        addSubview(subtitle)

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = coral
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.title = "Refresh offers"
        config.image = UIImage(systemName: "arrow.clockwise")
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 24, bottom: 13, trailing: 24)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = EmptyInboxView.roundedFont(16, .semibold)
            return out
        }
        let refresh = UIButton(configuration: config)
        refresh.translatesAutoresizingMaskIntoConstraints = false
        refresh.addAction(UIAction { [weak self] _ in self?.onRefresh?() }, for: .touchUpInside)
        addSubview(refresh)

        NSLayoutConstraint.activate([
            halo.centerXAnchor.constraint(equalTo: centerXAnchor),
            halo.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -96),
            halo.widthAnchor.constraint(equalToConstant: 128),
            halo.heightAnchor.constraint(equalToConstant: 128),

            glyph.centerXAnchor.constraint(equalTo: halo.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: halo.centerYAnchor),
            glyph.widthAnchor.constraint(equalToConstant: 64),
            glyph.heightAnchor.constraint(equalToConstant: 64),

            title.topAnchor.constraint(equalTo: halo.bottomAnchor, constant: 28),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            subtitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36),
            subtitle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -36),

            refresh.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 24),
            refresh.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        // Subtle float on the glyph.
        let anim = CABasicAnimation(keyPath: "transform.translation.y")
        anim.fromValue = -6
        anim.toValue = 6
        anim.duration = 2.8
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glyph.layer.add(anim, forKey: "float")
    }

    private static func roundedFont(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }
}

/// Celebratory "Added to Apple Wallet" confirmation. Apple-minimal: one spring-loaded green
/// check with a single expanding pulse ring, a success haptic, and staggered text — restrained,
/// not confetti.
private struct WalletAddedView: View {
    let passTitle: String
    @Environment(\.dismiss) private var dismiss

    @State private var badgeIn = false
    @State private var pulse = false
    @State private var textIn = false

    private let green = Color(red: 0.18, green: 0.89, blue: 0.61)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(green.opacity(0.55), lineWidth: 2)
                    .frame(width: 108, height: 108)
                    .scaleEffect(pulse ? 2.1 : 0.9)
                    .opacity(pulse ? 0 : 0.9)

                Circle()
                    .fill(green)
                    .frame(width: 108, height: 108)
                    .shadow(color: green.opacity(0.45), radius: 26, y: 12)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(badgeIn ? 1 : 0.3)
            .opacity(badgeIn ? 1 : 0)

            VStack(spacing: 8) {
                Text("Added to Apple Wallet")
                    .font(.system(size: 22, weight: .semibold))
                    .multilineTextAlignment(.center)
                Text(passTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 30)
            .padding(.horizontal, 32)
            .opacity(textIn ? 1 : 0)
            .offset(y: textIn ? 0 : 12)

            Spacer()

            Button { dismiss() } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .opacity(textIn ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { badgeIn = true }
            withAnimation(.easeOut(duration: 0.7)) { pulse = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.18)) { textIn = true }
        }
    }
}

#Preview {
    InboxKitView()
}
