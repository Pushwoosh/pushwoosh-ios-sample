//
//  MediaView.swift
//  PushwooshSampleApp
//

import SwiftUI
import PushwooshFramework

struct MediaView: View {
    // Presentation Style
    @State private var showStyleSheet = false
    @State private var selectedStyle: PWRichMediaPresentationStyle = .modal

    // Modal Position
    @State private var showPositionSheet = false
    @State private var selectedPosition: ModalWindowPosition = .PWModalWindowPositionBottom

    // Present Animation
    @State private var showPresentAnimationSheet = false
    @State private var selectedPresentAnimation: PresentModalWindowAnimation = .PWAnimationPresentSlideUp

    // Dismiss Animation
    @State private var showDismissAnimationSheet = false
    @State private var selectedDismissAnimation: DismissModalWindowAnimation = .PWAnimationDismissSlideDown

    // Swipe Directions
    @State private var showSwipeSheet = false
    @State private var swipeDown = true
    @State private var swipeUp = false
    @State private var swipeLeft = false
    @State private var swipeRight = false

    // Haptic Feedback
    @State private var showHapticSheet = false
    @State private var selectedHaptic: HapticFeedbackType = .PWHapticFeedbackMedium

    // Corner Settings
    @State private var showCornerSheet = false
    @State private var cornerTopLeft = true
    @State private var cornerTopRight = true
    @State private var cornerBottomLeft = false
    @State private var cornerBottomRight = false
    @State private var cornerRadius: Double = 16

    // Auto Close
    @State private var closeAfterEnabled = false
    @State private var closeAfterSeconds: Double = 5

    // Animation Duration
    @State private var customDurationEnabled = false
    @State private var animationDurationSeconds: Double = 0.3

    // Server Simulation
    // Reveals the rich media demo buttons. Routing is not switched here any more: the endpoint travels
    // with the application code chosen in Switch account, so the demo always talks to that region.
    @AppStorage("PWMockServerEnabled") private var richMediaDemoExpanded = false
    @State private var mockServerError: String?

    var body: some View {
        ZStack {
            PushMartBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView

                    // Presentation Style Card
                    presentationStyleCard

                    // Modal Settings (only visible when modal style selected)
                    if selectedStyle == .modal {
                        modalSettingsCard
                        animationsCard
                        animationDurationCard
                        swipeDirectionsCard
                        hapticFeedbackCard
                        cornerSettingsCard
                        autoCloseCard
                    }

                    // Apply Button
                    applyButton

                    // Server Simulation Card
                    serverSimulationCard

                    // Info Card
                    infoCard

                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showStyleSheet) {
            StyleSelectionSheet(selectedStyle: $selectedStyle)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPositionSheet) {
            PositionSelectionSheet(selectedPosition: $selectedPosition)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPresentAnimationSheet) {
            PresentAnimationSheet(selectedAnimation: $selectedPresentAnimation)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showDismissAnimationSheet) {
            DismissAnimationSheet(selectedAnimation: $selectedDismissAnimation)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSwipeSheet) {
            SwipeDirectionsSheet(
                swipeDown: $swipeDown,
                swipeUp: $swipeUp,
                swipeLeft: $swipeLeft,
                swipeRight: $swipeRight
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showHapticSheet) {
            HapticFeedbackSheet(selectedHaptic: $selectedHaptic)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showCornerSheet) {
            CornerSettingsSheet(
                topLeft: $cornerTopLeft,
                topRight: $cornerTopRight,
                bottomLeft: $cornerBottomLeft,
                bottomRight: $cornerBottomRight,
                radius: $cornerRadius
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Appearance").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("How your offers look in-app").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Presentation Style Card
    private var presentationStyleCard: some View {
        PushMartCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundColor(.mint)
                    Text("Presentation Style")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }

                SelectionButton(
                    title: "Style",
                    value: styleDisplayName,
                    color: .mint
                ) {
                    showStyleSheet = true
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                Text("Choose how Rich Media content is displayed. Modal allows customization of position and animations.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Modal Settings Card
    private var modalSettingsCard: some View {
        PushMartCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "square.on.square")
                        .foregroundColor(.blue)
                    Text("Modal Position")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }

                SelectionButton(
                    title: "Position",
                    value: positionDisplayName,
                    color: .blue
                ) {
                    showPositionSheet = true
                }
            }
        }
    }

    // MARK: - Animations Card
    private var animationsCard: some View {
        PushMartCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.purple)
                    Text("Animations")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }

                SelectionButton(
                    title: "Present Animation",
                    value: presentAnimationDisplayName,
                    color: .purple
                ) {
                    showPresentAnimationSheet = true
                }

                SelectionButton(
                    title: "Dismiss Animation",
                    value: dismissAnimationDisplayName,
                    color: .pink
                ) {
                    showDismissAnimationSheet = true
                }
            }
        }
    }

    // MARK: - Swipe Directions Card
    private var swipeDirectionsCard: some View {
        PushMartCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "hand.draw.fill")
                        .foregroundColor(.orange)
                    Text("Swipe to Dismiss")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }

                SelectionButton(
                    title: "Directions",
                    value: swipeDirectionsDisplayName,
                    color: .orange
                ) {
                    showSwipeSheet = true
                }
            }
        }
    }

    // MARK: - Haptic Feedback Card
    private var hapticFeedbackCard: some View {
        PushMartCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .foregroundColor(.cyan)
                    Text("Haptic Feedback")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }

                SelectionButton(
                    title: "Feedback Type",
                    value: hapticDisplayName,
                    color: .cyan
                ) {
                    showHapticSheet = true
                }
            }
        }
    }

    // MARK: - Corner Settings Card
    private var cornerSettingsCard: some View {
        PushMartCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "rectangle.roundedtop.fill")
                        .foregroundColor(.indigo)
                    Text("Corner Radius")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }

                SelectionButton(
                    title: "Corners",
                    value: cornerDisplayName,
                    color: .indigo
                ) {
                    showCornerSheet = true
                }

                HStack {
                    Text("Radius: \(Int(cornerRadius))pt")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }

                Slider(value: $cornerRadius, in: 0...50, step: 1)
                    .tint(.indigo)
            }
        }
    }

    // MARK: - Auto Close Card
    private var autoCloseCard: some View {
        PushMartCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "timer")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto Close")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text(closeAfterEnabled ? "\(Int(closeAfterSeconds)) seconds" : "Disabled")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(closeAfterEnabled ? .green : .red.opacity(0.7))
                    }

                    Spacer()

                    Toggle("", isOn: $closeAfterEnabled)
                        .tint(.red)
                        .scaleEffect(0.9)
                }

                if closeAfterEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Close after: \(Int(closeAfterSeconds)) seconds")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                        }

                        Slider(value: $closeAfterSeconds, in: 1...60, step: 1)
                            .tint(.red)
                    }
                }
            }
        }
    }

    // MARK: - Animation Duration Card
    private var animationDurationCard: some View {
        PushMartCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "speedometer")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Animation Duration")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text(customDurationEnabled ? String(format: "%.1f seconds", animationDurationSeconds) : "Default (0.3s)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(customDurationEnabled ? .green : .white.opacity(0.5))
                    }

                    Spacer()

                    Toggle("", isOn: $customDurationEnabled)
                        .tint(.purple)
                        .scaleEffect(0.9)
                }

                if customDurationEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text(String(format: "Duration: %.1f seconds", animationDurationSeconds))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                        }

                        Slider(value: $animationDurationSeconds, in: 0.1...3.0, step: 0.1)
                            .tint(.purple)
                    }
                }
            }
        }
    }

    // MARK: - Apply Button
    private var applyButton: some View {
        ModernButton(
            title: "Apply Settings",
            icon: "checkmark.circle.fill",
            gradient: [.mint, .teal]
        ) {
            applySettings()
        }
        .sdkNote("Pushwoosh.media.setRichMediaPresentationStyle(_:) + modalRichMedia config",
                 "Applying saves the presentation style and every modal appearance option - position, animations, swipe-to-dismiss, haptics, corners and auto-close - into the SDK for the next Rich Media.",
                 docs: "modalRichMedia calls only run when the Modal style is selected. Durations are in seconds and 0 means keep the SDK default. The global PWRichMediaStyle controls the shared loading backdrop, status bar and inline video playback across every Rich Media.",
                 calls: [
                    .init(code: "Pushwoosh.media.setRichMediaPresentationStyle(selectedStyle)",
                          note: "Chooses whether Rich Media shows as a customizable Modal or the full-screen Legacy style."),
                    .init(code: "Pushwoosh.media.richMediaPresentationStyle()",
                          note: "Reads the style back to confirm the SDK stored it (logged as the raw value)."),
                    .init(code: "PWRichMediaManager.shared().richMediaStyle = PWRichMediaStyle()",
                          note: "Sets global Rich Media appearance: dimmed backdrop, status bar visibility and inline video playback."),
                    .init(code: "Pushwoosh.media.modalRichMedia.configure(with: selectedPosition, present: selectedPresentAnimation, dismiss: selectedDismissAnimation)",
                          note: "Applies the chosen modal position and the present/dismiss animations."),
                    .init(code: "Pushwoosh.media.modalRichMedia.setAnimationDuration(customDurationEnabled ? animationDurationSeconds : 0)",
                          note: "Sets the modal animation duration in seconds; 0 keeps the SDK's default timing."),
                    .init(code: "Pushwoosh.media.modalRichMedia.setDismissSwipeDirections(directions)",
                          note: "Sets which swipe directions dismiss the modal (down/up/left/right, or none)."),
                    .init(code: "Pushwoosh.media.modalRichMedia.setHapticFeedbackType(selectedHaptic)",
                          note: "Sets the haptic played when the modal appears (light/medium/hard/none)."),
                    .init(code: "Pushwoosh.media.modalRichMedia.setCornerType(CornerType(rawValue: cornerType), withRadius: cornerRadius)",
                          note: "Rounds the selected corners of the modal to the chosen radius."),
                    .init(code: "Pushwoosh.media.modalRichMedia.close(after: closeAfterEnabled ? closeAfterSeconds : 0)",
                          note: "Auto-closes the modal after the given seconds; 0 disables auto-close.")
                 ])
    }

    // MARK: - Server Simulation Card
    private var serverSimulationCard: some View {
        PushMartCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "server.rack")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server Simulation")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Bundled rich media, answered by this region's local server")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(richMediaDemoExpanded ? .green : .white.opacity(0.5))
                    }

                    Spacer()

                    Toggle("", isOn: $richMediaDemoExpanded)
                        .tint(.orange)
                        .scaleEffect(0.9)
                }

                if richMediaDemoExpanded {
                    Text("Self-contained: the selected region points at a local server that serves the bundled rich media. Just tap a button below.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ModernButton(
                        title: "Campaign as-is",
                        icon: "photo.on.rectangle.angled",
                        gradient: [.orange, .red]
                    ) {
                        triggerMockRichMedia(event: "showRichMedia")
                    }

                    ModernButton(
                        title: "Client API settings",
                        icon: "slider.horizontal.3",
                        gradient: [.purple, .indigo]
                    ) {
                        applySettings()
                        triggerMockRichMedia(event: "showRichMediaClient")
                    }

                    ModernButton(
                        title: "Server style_settings",
                        icon: "server.rack",
                        gradient: [.teal, .green]
                    ) {
                        LocalPushwooshServer.simulatedStyleSettings = simulatedServerStyleSettings()
                        triggerMockRichMedia(event: "showRichMediaServer")
                    }
                    .sdkNote("PWInAppManager.shared().postEvent(_:withAttributes:completion:)",
                             "Each button posts an in-app event that Pushwoosh matches to the bundled Rich Media, served here by the local mock server.",
                             docs: "The event still reaches Pushwoosh exactly as in production; only the server responding to it is the in-app mock the selected region points at.",
                             calls: [
                                .init(code: "postEvent(\"showRichMedia\", withAttributes: [:])",
                                      note: "Campaign as-is - presents the campaign's Rich Media exactly as configured on the dashboard."),
                                .init(code: "postEvent(\"showRichMediaClient\", withAttributes: [:])",
                                      note: "Client API settings - re-applies the modal settings above through the SDK, then shows the same message with those client-side overrides."),
                                .init(code: "postEvent(\"showRichMediaServer\", withAttributes: [:])",
                                      note: "Server style_settings - shows the same message with style_settings simulated from the server side.")
                             ])

                    ModernButton(
                        title: "Native in-app (split)",
                        icon: "bubble.left.and.bubble.right.fill",
                        gradient: [.pink, .purple]
                    ) {
                        triggerMockRichMedia(event: "showNativeInApp")
                    }
                    .sdkNote("Native in-app split (postEvent -> ZIP -> native-config.json)",
                             "The mock server serves a rich-media ZIP that also contains native-config.json. The SDK downloads and unzips it, detects the native config, and routes it to the PushwooshInApp module instead of the HTML rich media.",
                             docs: "Same production chain as the buttons above; the only difference is the ZIP carries a native-config.json, which the SDK's splitter picks up and hands to the native in-app module.",
                             calls: [
                                .init(code: "postEvent(\"showNativeInApp\", withAttributes: [:])",
                                      note: "Serves a ZIP with native-config.json - the splitter renders a native modal instead of the HTML rich media.")
                             ])

                    if let error = mockServerError {
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func triggerMockRichMedia(event: String) {
        mockServerError = nil
        PushwooshHelper.safeCall {
            PWInAppManager.shared().postEvent(event, withAttributes: [:]) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        mockServerError = "postEvent failed: \(error.localizedDescription). Is the mock server running?"
                    }
                }
            }
        }
    }

    // Maps the UI selections to server-side style_settings strings (what the campaign
    // editor would put into pushwoosh.json).
    private func simulatedServerStyleSettings() -> [String: Any] {
        var styles: [String: Any] = [:]

        switch selectedPosition {
        case .PWModalWindowPositionTop: styles["position"] = "top"
        case .PWModalWindowPositionCenter: styles["position"] = "center"
        case .PWModalWindowPositionBottom: styles["position"] = "bottom"
        case .PWModalWindowPositionFullScreen: styles["position"] = "fullscreen"
        default: break
        }

        switch selectedPresentAnimation {
        case .PWAnimationPresentSlideUp: styles["present_animation"] = "up"
        case .PWAnimationPresentDropDown: styles["present_animation"] = "down"
        case .PWAnimationPresentSlideFromLeft: styles["present_animation"] = "left"
        case .PWAnimationPresentSlideFromRight: styles["present_animation"] = "right"
        case .PWAnimationPresentFadeIn: styles["present_animation"] = "fade_in"
        case .PWAnimationPresentNone: styles["present_animation"] = "none"
        default: break
        }

        switch selectedDismissAnimation {
        case .PWAnimationDismissSlideUp: styles["dismiss_animation"] = "up"
        case .PWAnimationDismissSlideDown: styles["dismiss_animation"] = "down"
        case .PWAnimationDismissSlideLeft: styles["dismiss_animation"] = "left"
        case .PWAnimationDismissSlideRight: styles["dismiss_animation"] = "right"
        case .PWAnimationDismissFadeOut: styles["dismiss_animation"] = "fade_out"
        case .PWAnimationDismissNone: styles["dismiss_animation"] = "none"
        default: break
        }

        var swipes: [String] = []
        if swipeDown { swipes.append("down") }
        if swipeUp { swipes.append("up") }
        if swipeLeft { swipes.append("left") }
        if swipeRight { swipes.append("right") }
        styles["swipe_to_dismiss"] = swipes

        if customDurationEnabled {
            styles["animation_duration"] = Int(animationDurationSeconds * 1000)
        }

        return styles
    }

    // MARK: - Info Card
    private var infoCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("About Rich Media")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    InfoNoteRow(
                        icon: "rectangle.stack.fill",
                        text: "Modal: Customizable popup window with animations",
                        color: .mint
                    )

                    InfoNoteRow(
                        icon: "rectangle.fill",
                        text: "Legacy: Full-screen presentation style",
                        color: .blue
                    )

                    InfoNoteRow(
                        icon: "hand.draw.fill",
                        text: "Swipe gestures allow users to dismiss the content",
                        color: .orange
                    )
                }
            }
        }
    }

    // MARK: - Display Names
    private var styleDisplayName: String {
        switch selectedStyle {
        case .modal: return "Modal"
        case .legacy: return "Legacy"
        @unknown default: return "Unknown"
        }
    }

    private var positionDisplayName: String {
        switch selectedPosition {
        case .PWModalWindowPositionTop: return "Top"
        case .PWModalWindowPositionCenter: return "Center"
        case .PWModalWindowPositionBottom: return "Bottom"
        case .PWModalWindowPositionBottomSheet: return "Bottom Sheet"
        case .PWModalWindowPositionFullScreen: return "Full Screen"
        case .PWModalWindowPositionDefault: return "Default"
        @unknown default: return "Unknown"
        }
    }

    private var presentAnimationDisplayName: String {
        switch selectedPresentAnimation {
        case .PWAnimationPresentSlideUp: return "From Bottom"
        case .PWAnimationPresentDropDown: return "From Top"
        case .PWAnimationPresentSlideFromRight: return "From Right"
        case .PWAnimationPresentSlideFromLeft: return "From Left"
        case .PWAnimationPresentFadeIn: return "Fade In"
        case .PWAnimationPresentNone: return "None"
        @unknown default: return "Unknown"
        }
    }

    private var dismissAnimationDisplayName: String {
        switch selectedDismissAnimation {
        case .PWAnimationDismissSlideDown: return "Down"
        case .PWAnimationDismissSlideUp: return "Up"
        case .PWAnimationDismissSlideLeft: return "Left"
        case .PWAnimationDismissSlideRight: return "Right"
        case .PWAnimationDismissFadeOut: return "Fade Out"
        case .PWAnimationCurveEaseInOut: return "Ease In Out"
        case .PWAnimationDismissNone: return "None"
        case .PWAnimationDismissDefault: return "Default"
        @unknown default: return "Unknown"
        }
    }

    private var swipeDirectionsDisplayName: String {
        var directions: [String] = []
        if swipeDown { directions.append("Down") }
        if swipeUp { directions.append("Up") }
        if swipeLeft { directions.append("Left") }
        if swipeRight { directions.append("Right") }
        return directions.isEmpty ? "None" : directions.joined(separator: ", ")
    }

    private var hapticDisplayName: String {
        switch selectedHaptic {
        case .PWHapticFeedbackLight: return "Light"
        case .PWHapticFeedbackMedium: return "Medium"
        case .PWHapticFeedbackHard: return "Hard"
        case .PWHapticFeedbackNone: return "None"
        @unknown default: return "Unknown"
        }
    }

    private var cornerDisplayName: String {
        var corners: [String] = []
        if cornerTopLeft { corners.append("TL") }
        if cornerTopRight { corners.append("TR") }
        if cornerBottomLeft { corners.append("BL") }
        if cornerBottomRight { corners.append("BR") }
        return corners.isEmpty ? "None" : corners.joined(separator: ", ")
    }

    // MARK: - Apply Settings
    private func applySettings() {
        PushwooshHelper.safeCall {
            // Set presentation style
            Pushwoosh.media.setRichMediaPresentationStyle(selectedStyle)

            // Read the style back through the getter to confirm it took.
            print("Rich media presentation style: \(Pushwoosh.media.richMediaPresentationStyle().rawValue)")

            // Global rich-media appearance (loading backdrop, status bar, inline video playback).
            let richStyle = PWRichMediaStyle()
            richStyle.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            richStyle.closeButtonPresentingDelay = 0
            richStyle.shouldHideStatusBar = false
            richStyle.allowsInlineMediaPlayback = NSNumber(value: true)
            richStyle.mediaPlaybackRequiresUserAction = NSNumber(value: false)
            PWRichMediaManager.shared().richMediaStyle = richStyle

            if selectedStyle == .modal {
                // Configure modal window
                Pushwoosh.media.modalRichMedia.configure(
                    with: selectedPosition,
                    present: selectedPresentAnimation,
                    dismiss: selectedDismissAnimation
                )

                // Set animation duration (0 = SDK default timing)
                Pushwoosh.media.modalRichMedia.setAnimationDuration(customDurationEnabled ? animationDurationSeconds : 0)

                // Set swipe directions
                var directions: [NSNumber] = []
                if swipeDown { directions.append(NSNumber(value: DismissSwipeDirection.PWSwipeDismissDown.rawValue)) }
                if swipeUp { directions.append(NSNumber(value: DismissSwipeDirection.PWSwipeDismissUp.rawValue)) }
                if swipeLeft { directions.append(NSNumber(value: DismissSwipeDirection.PWSwipeDismissLeft.rawValue)) }
                if swipeRight { directions.append(NSNumber(value: DismissSwipeDirection.PWSwipeDismissRight.rawValue)) }
                if directions.isEmpty {
                    directions.append(NSNumber(value: DismissSwipeDirection.PWSwipeDismissNone.rawValue))
                }
                Pushwoosh.media.modalRichMedia.setDismissSwipeDirections(directions)

                // Set haptic feedback
                Pushwoosh.media.modalRichMedia.setHapticFeedbackType(selectedHaptic)

                // Set corner radius
                var cornerType: UInt = 0
                if cornerTopLeft { cornerType |= CornerType.PWCornerTypeTopLeft.rawValue }
                if cornerTopRight { cornerType |= CornerType.PWCornerTypeTopRight.rawValue }
                if cornerBottomLeft { cornerType |= CornerType.PWCornerTypeBottomLeft.rawValue }
                if cornerBottomRight { cornerType |= CornerType.PWCornerTypeBottomRight.rawValue }
                Pushwoosh.media.modalRichMedia.setCornerType(CornerType(rawValue: cornerType), withRadius: cornerRadius)

                // Set auto close
                if closeAfterEnabled {
                    Pushwoosh.media.modalRichMedia.close(after: closeAfterSeconds)
                } else {
                    Pushwoosh.media.modalRichMedia.close(after: 0)
                }
            }
        }
        PushMartResult.shared.success("Settings applied", "Rich media appearance updated.")
    }
}

// MARK: - Selection Button
struct SelectionButton: View {
    let title: String
    let value: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)

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

// MARK: - Style Selection Sheet
struct StyleSelectionSheet: View {
    @Binding var selectedStyle: PWRichMediaPresentationStyle
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Button {
                    selectedStyle = .modal
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "square.on.square")
                            .foregroundColor(.mint)
                        Text("Modal")
                        Spacer()
                        if selectedStyle == .modal {
                            Image(systemName: "checkmark")
                                .foregroundColor(.mint)
                        }
                    }
                }

                Button {
                    selectedStyle = .legacy
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.fill")
                            .foregroundColor(.blue)
                        Text("Legacy")
                        Spacer()
                        if selectedStyle == .legacy {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Presentation Style")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Position Selection Sheet
struct PositionSelectionSheet: View {
    @Binding var selectedPosition: ModalWindowPosition
    @Environment(\.dismiss) var dismiss

    private let positions: [(ModalWindowPosition, String, String)] = [
        (.PWModalWindowPositionTop, "Top", "rectangle.topthird.inset.filled"),
        (.PWModalWindowPositionCenter, "Center", "rectangle.center.inset.filled"),
        (.PWModalWindowPositionBottom, "Bottom", "rectangle.bottomthird.inset.filled"),
        (.PWModalWindowPositionBottomSheet, "Bottom Sheet", "rectangle.bottomhalf.inset.filled"),
        (.PWModalWindowPositionFullScreen, "Full Screen", "rectangle.inset.filled"),
        (.PWModalWindowPositionDefault, "Default", "rectangle")
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(positions, id: \.1) { position, name, icon in
                    Button {
                        selectedPosition = position
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(.blue)
                            Text(name)
                            Spacer()
                            if selectedPosition == position {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Modal Position")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Present Animation Sheet
struct PresentAnimationSheet: View {
    @Binding var selectedAnimation: PresentModalWindowAnimation
    @Environment(\.dismiss) var dismiss

    private let animations: [(PresentModalWindowAnimation, String, String)] = [
        (.PWAnimationPresentSlideUp, "From Bottom", "arrow.up"),
        (.PWAnimationPresentDropDown, "From Top", "arrow.down"),
        (.PWAnimationPresentSlideFromRight, "From Right", "arrow.left"),
        (.PWAnimationPresentSlideFromLeft, "From Left", "arrow.right"),
        (.PWAnimationPresentFadeIn, "Fade In", "sparkles"),
        (.PWAnimationPresentNone, "None", "xmark")
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(animations, id: \.1) { animation, name, icon in
                    Button {
                        selectedAnimation = animation
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(.purple)
                            Text(name)
                            Spacer()
                            if selectedAnimation == animation {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Present Animation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Dismiss Animation Sheet
struct DismissAnimationSheet: View {
    @Binding var selectedAnimation: DismissModalWindowAnimation
    @Environment(\.dismiss) var dismiss

    private let animations: [(DismissModalWindowAnimation, String, String)] = [
        (.PWAnimationDismissSlideDown, "Down", "arrow.down"),
        (.PWAnimationDismissSlideUp, "Up", "arrow.up"),
        (.PWAnimationDismissSlideLeft, "Left", "arrow.left"),
        (.PWAnimationDismissSlideRight, "Right", "arrow.right"),
        (.PWAnimationDismissFadeOut, "Fade Out", "sparkles"),
        (.PWAnimationCurveEaseInOut, "Ease In Out", "waveform.path"),
        (.PWAnimationDismissNone, "None", "xmark"),
        (.PWAnimationDismissDefault, "Default", "arrow.uturn.backward")
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(animations, id: \.1) { animation, name, icon in
                    Button {
                        selectedAnimation = animation
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(.pink)
                            Text(name)
                            Spacer()
                            if selectedAnimation == animation {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dismiss Animation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Swipe Directions Sheet
struct SwipeDirectionsSheet: View {
    @Binding var swipeDown: Bool
    @Binding var swipeUp: Bool
    @Binding var swipeLeft: Bool
    @Binding var swipeRight: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Toggle(isOn: $swipeDown) {
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.orange)
                        Text("Swipe Down")
                    }
                }
                .tint(.orange)

                Toggle(isOn: $swipeUp) {
                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.orange)
                        Text("Swipe Up")
                    }
                }
                .tint(.orange)

                Toggle(isOn: $swipeLeft) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.orange)
                        Text("Swipe Left")
                    }
                }
                .tint(.orange)

                Toggle(isOn: $swipeRight) {
                    HStack {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.orange)
                        Text("Swipe Right")
                    }
                }
                .tint(.orange)
            }
            .navigationTitle("Swipe Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Haptic Feedback Sheet
struct HapticFeedbackSheet: View {
    @Binding var selectedHaptic: HapticFeedbackType
    @Environment(\.dismiss) var dismiss

    private let haptics: [(HapticFeedbackType, String, String)] = [
        (.PWHapticFeedbackLight, "Light", "circle"),
        (.PWHapticFeedbackMedium, "Medium", "circle.fill"),
        (.PWHapticFeedbackHard, "Hard", "circle.inset.filled"),
        (.PWHapticFeedbackNone, "None", "circle.slash")
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(haptics, id: \.1) { haptic, name, icon in
                    Button {
                        selectedHaptic = haptic
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(.cyan)
                            Text(name)
                            Spacer()
                            if selectedHaptic == haptic {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Haptic Feedback")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Corner Settings Sheet
struct CornerSettingsSheet: View {
    @Binding var topLeft: Bool
    @Binding var topRight: Bool
    @Binding var bottomLeft: Bool
    @Binding var bottomRight: Bool
    @Binding var radius: Double
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Corners to Round") {
                    Toggle(isOn: $topLeft) {
                        HStack {
                            Image(systemName: "arrow.up.left")
                                .foregroundColor(.indigo)
                            Text("Top Left")
                        }
                    }
                    .tint(.indigo)

                    Toggle(isOn: $topRight) {
                        HStack {
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.indigo)
                            Text("Top Right")
                        }
                    }
                    .tint(.indigo)

                    Toggle(isOn: $bottomLeft) {
                        HStack {
                            Image(systemName: "arrow.down.left")
                                .foregroundColor(.indigo)
                            Text("Bottom Left")
                        }
                    }
                    .tint(.indigo)

                    Toggle(isOn: $bottomRight) {
                        HStack {
                            Image(systemName: "arrow.down.right")
                                .foregroundColor(.indigo)
                            Text("Bottom Right")
                        }
                    }
                    .tint(.indigo)
                }

                Section("Radius: \(Int(radius))pt") {
                    Slider(value: $radius, in: 0...50, step: 1)
                        .tint(.indigo)
                }
            }
            .navigationTitle("Corner Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MediaView()
}
