//
//  InAppDemoScreens.swift
//  PushwooshSampleApp
//
//  Presentation screens for the native in-app module: one immersive, themed
//  screen per template. Each screen looks like a real page of a luxury car
//  showroom app ("APEX MOTORS" — same world as the demo configs), so the
//  in-app presents over believable app content instead of a button list.
//

import SwiftUI
import PushwooshFramework
import PushwooshInApp

// MARK: - Screen registry

enum InAppDemoScreen: String, CaseIterable, Identifiable {
    case modal
    case sheet
    case carousel
    case stories
    case fullscreen
    case bannerBottom
    case bannerTop
    case video
    case pip
    case scratchCard
    case spinWheel

    var id: String { rawValue }
}

struct InAppDemoScreenView: View {
    let screen: InAppDemoScreen

    var body: some View {
        switch screen {
        case .modal: ShowroomDemoScreen()
        case .sheet: TradeInDemoScreen()
        case .carousel: ArrivalsDemoScreen()
        case .stories: HighlightsDemoScreen()
        case .fullscreen: CollectionDemoScreen()
        case .bannerBottom: InventoryDemoScreen()
        case .bannerTop: AlertsDemoScreen()
        case .video: PremiereDemoScreen()
        case .pip: ConfiguratorDemoScreen()
        case .scratchCard: ScratchRewardDemoScreen()
        case .spinWheel: SpinWheelDemoScreen()
        }
    }
}

// MARK: - Shared demo assets

/// Pexels photos (hotlink-friendly). `fit=crop` serves the exact aspect each
/// surface renders: landscape for cards/banners, portrait for the aspect-fill
/// carousel cards and full-screen stories — so nothing gets cropped awkwardly.
private enum DemoCar {
    static let amg = pexels(3729464, w: 1280, h: 850)
    static let amgPortrait = pexels(3729464, w: 1080, h: 1620)
    static let alpine = pexels(1592384, w: 1280, h: 850)
    static let alpinePortrait = pexels(1592384, w: 1080, h: 1620)
    static let ferrari = pexels(337909, w: 1280, h: 850)
    static let ferrariPortrait = pexels(337909, w: 1080, h: 1620)

    // Image-handling demo — one fresh photo per display type, at the ratio that type wants
    // (picsum serves an exact size per seed, so every button shows a genuinely different image).
    static let imageModal = picsum("pw-modal-2026", w: 1200, h: 1200)            // modal → 1:1 square
    static let imageFullscreen = picsum("pw-fullscreen-2026", w: 1200, h: 2133)  // fullscreen → 9:16 portrait
    static let imageStory1 = picsum("pw-story-a-2026", w: 1200, h: 2133)         // stories → 9:16 portrait
    static let imageStory2 = picsum("pw-story-b-2026", w: 1200, h: 2133)
    static let imageStory3 = picsum("pw-story-c-2026", w: 1200, h: 2133)
    static let imageModalPortrait = picsum("pw-modal-portrait-2026", w: 900, h: 1200) // 3:4 portrait — fits whole
    static let imageModalTall = picsum("pw-modal-tall-2026", w: 600, h: 2400)    // 1:4 — taller than the card cap, fitted whole

    private static func picsum(_ seed: String, w: Int, h: Int) -> URL {
        URL(string: "https://picsum.photos/seed/\(seed)/\(w)/\(h)")!
    }

    private static func pexels(_ id: Int, w: Int, h: Int) -> URL {
        URL(string: "https://images.pexels.com/photos/\(id)/pexels-photo-\(id).jpeg?auto=compress&cs=tinysrgb&fit=crop&w=\(w)&h=\(h)")!
    }
}

// MARK: - Shared chrome

/// Full-screen scaffold shared by every demo screen: dark showroom background
/// with an accent glow, brand top bar with a back button, scrollable themed
/// content, and a pinned trigger that presents the in-app over this screen.
private struct DemoChrome<Content: View>: View {
    let accent: Color
    let trigger: String
    let config: [AnyHashable: Any]
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Color(red: 0.043, green: 0.043, blue: 0.063)
                Circle()
                    .fill(accent.opacity(0.35))
                    .frame(width: 360, height: 360)
                    .blur(radius: 120)
                    .offset(x: 120, y: -300)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    content()
                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 24)
            }

            triggerButton
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.white.opacity(0.1)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
            }
            Spacer()
            Text("APEX MOTORS")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .tracking(4)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                )
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var triggerButton: some View {
        Button {
            Pushwoosh.inApp.present(config)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                Text(trigger)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Capsule().fill(accent))
            .shadow(color: accent.opacity(0.45), radius: 18, y: 10)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 12)
    }
}

private struct DemoSectionTitle: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundColor(.white.opacity(0.5))
            Text(title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

private struct DemoCarImage: View {
    let url: URL
    var height: CGFloat = 180

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            default:
                Rectangle().fill(.white.opacity(0.06))
                    .overlay(ProgressView().tint(.white.opacity(0.4)))
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct DemoRow: View {
    let image: URL?
    let icon: String?
    let iconTint: Color
    let title: String
    let subtitle: String
    let detail: String?
    let detailTint: Color

    init(image: URL? = nil, icon: String? = nil, iconTint: Color = .white,
         title: String, subtitle: String, detail: String? = nil, detailTint: Color = .white) {
        self.image = image
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.detailTint = detailTint
    }

    var body: some View {
        HStack(spacing: 14) {
            if let image = image {
                AsyncImage(url: image) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(.white.opacity(0.08))
                    }
                }
                .frame(width: 62, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(iconTint)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(iconTint.opacity(0.14)))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer()
            if let detail = detail {
                Text(detail)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(detailTint)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - 1. Modal — showroom home

private struct ShowroomDemoScreen: View {
    var body: some View {
        DemoChrome(accent: Color(red: 1.0, green: 0.23, blue: 0.19),
                   trigger: "Show promo modal",
                   config: InAppDemoConfigs.modal) {
            DemoSectionTitle(eyebrow: "Showroom", title: "This week's floor")

            VStack(alignment: .leading, spacing: 10) {
                DemoCarImage(url: DemoCar.amg, height: 210)
                Text("AMG GT R")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("585 hp · biturbo V8 · on the floor now")
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.top, 24)

            VStack(spacing: 12) {
                DemoRow(image: DemoCar.alpine, title: "Alpine A110",
                        subtitle: "Featherweight mid-engine icon", detail: "NEW", detailTint: .orange)
                DemoRow(image: DemoCar.ferrari, title: "Ferrari 458",
                        subtitle: "Maranello icon — viewing by appointment")
            }
            .padding(.top, 24)
        }
    }
}

// MARK: - 1b. Sheet — trade-in garage

private struct TradeInDemoScreen: View {
    var body: some View {
        DemoChrome(accent: .mint,
                   trigger: "Show bottom sheet",
                   config: InAppDemoConfigs.sheet) {
            DemoSectionTitle(eyebrow: "My garage", title: "Your trade-in")

            VStack(alignment: .leading, spacing: 10) {
                DemoCarImage(url: DemoCar.alpine, height: 200)
                Text("Alpine A110 · 2024")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("12,400 km · Alpine Blue · full service history")
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.top, 24)

            VStack(spacing: 12) {
                DemoRow(icon: "chart.line.uptrend.xyaxis", iconTint: .mint,
                        title: "Market value", subtitle: "Updated this morning",
                        detail: "$68,500", detailTint: .mint)
                DemoRow(icon: "clock.fill", iconTint: .mint,
                        title: "Quote validity", subtitle: "Guaranteed buyout price",
                        detail: "7 DAYS", detailTint: .white.opacity(0.7))
                DemoRow(icon: "arrow.triangle.2.circlepath", iconTint: .mint,
                        title: "Upgrade path", subtitle: "Trade in towards the GT R")
            }
            .padding(.top, 24)
        }
    }
}

// MARK: - 2. Carousel — new arrivals

private struct ArrivalsDemoScreen: View {
    var body: some View {
        DemoChrome(accent: .purple,
                   trigger: "Show carousel",
                   config: InAppDemoConfigs.carousel) {
            DemoSectionTitle(eyebrow: "New arrivals", title: "Fresh off the truck")

            VStack(spacing: 12) {
                DemoRow(image: DemoCar.amg, title: "AMG GT R",
                        subtitle: "Arrived Monday", detail: "3 SLOTS", detailTint: .green)
                DemoRow(image: DemoCar.alpine, title: "Alpine A110",
                        subtitle: "Arrived Wednesday", detail: "ALLOCATED", detailTint: .orange)
                DemoRow(image: DemoCar.ferrari, title: "Ferrari 458",
                        subtitle: "Arriving next week", detail: "WAITLIST", detailTint: .white.opacity(0.5))
                DemoRow(icon: "shippingbox.fill", iconTint: .purple,
                        title: "Pagani Utopia", subtitle: "In transit from Modena",
                        detail: "Q3", detailTint: .white.opacity(0.5))
            }
            .padding(.top, 24)
        }
    }
}

// MARK: - 3. Stories — highlights feed

private struct HighlightsDemoScreen: View {
    private struct Highlight: Identifiable {
        let id = UUID()
        let url: URL
        let label: String
        let colors: [Color]
    }

    private let highlights: [Highlight] = [
        .init(url: DemoCar.amg, label: "GT R", colors: [.pink, .orange]),
        .init(url: DemoCar.alpine, label: "A110", colors: [.purple, .blue]),
        .init(url: DemoCar.ferrari, label: "Ferrari", colors: [.red, .yellow]),
    ]

    var body: some View {
        DemoChrome(accent: .indigo,
                   trigger: "Show stories",
                   config: InAppDemoConfigs.stories) {
            DemoSectionTitle(eyebrow: "Highlights", title: "This week at APEX")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(highlights) { item in
                        VStack(spacing: 8) {
                            AsyncImage(url: item.url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Rectangle().fill(.white.opacity(0.08))
                                }
                            }
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                            .overlay(
                                Circle().strokeBorder(
                                    AngularGradient(colors: item.colors + [item.colors[0]],
                                                    center: .center),
                                    lineWidth: 3
                                )
                                .padding(-5)
                            )
                            Text(item.label)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(5)
                    }
                }
                .padding(.vertical, 6)
            }
            .padding(.top, 20)

            VStack(spacing: 12) {
                DemoRow(image: DemoCar.amg, title: "Track day recap",
                        subtitle: "The GT R's first laps at the ring")
                DemoRow(image: DemoCar.alpine, title: "Design deep-dive",
                        subtitle: "Inside the A110's featherweight chassis")
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - 4. Fullscreen — collection page

private struct CollectionDemoScreen: View {
    private let specs = ["V8 · 570 hp", "0–100 in 3.4s", "Carbon trim", "1 of 499"]

    var body: some View {
        DemoChrome(accent: .teal,
                   trigger: "Show fullscreen",
                   config: InAppDemoConfigs.fullscreen) {
            DemoSectionTitle(eyebrow: "The collection", title: "Pure Maranello")

            DemoCarImage(url: DemoCar.ferrari, height: 230)
                .padding(.top, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(specs, id: \.self) { spec in
                        Text(spec)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(.white.opacity(0.08))
                                    .overlay(Capsule().strokeBorder(.teal.opacity(0.5), lineWidth: 1))
                            )
                    }
                }
            }
            .padding(.top, 18)

            Text("The prancing horse, reimagined. Every allocation includes a factory tour in Maranello and a bespoke interior session with our design team.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(4)
                .padding(.top, 20)
        }
    }
}

// MARK: - 5. Bottom banner — inventory

private struct InventoryDemoScreen: View {
    var body: some View {
        DemoChrome(accent: .orange,
                   trigger: "Show bottom banner",
                   config: InAppDemoConfigs.bannerBottom) {
            DemoSectionTitle(eyebrow: "Inventory", title: "On the floor today")

            VStack(spacing: 12) {
                DemoRow(image: DemoCar.amg, title: "AMG GT R",
                        subtitle: "Green Hell Magno", detail: "IN STOCK", detailTint: .green)
                DemoRow(image: DemoCar.alpine, title: "Alpine A110",
                        subtitle: "Alpine Blue heritage", detail: "1 LEFT", detailTint: .orange)
                DemoRow(image: DemoCar.ferrari, title: "Ferrari 458",
                        subtitle: "Rosso Corsa, tan hide", detail: "RESERVED", detailTint: .white.opacity(0.5))
                DemoRow(icon: "key.fill", iconTint: .orange,
                        title: "Trade-in appraisal", subtitle: "Book a 20-minute valuation")
            }
            .padding(.top, 24)
        }
    }
}

// MARK: - 6. Top banner — stock alerts

private struct AlertsDemoScreen: View {
    var body: some View {
        DemoChrome(accent: .yellow,
                   trigger: "Show top banner",
                   config: InAppDemoConfigs.bannerTop) {
            DemoSectionTitle(eyebrow: "Alerts", title: "Your watchlist")

            VStack(spacing: 12) {
                DemoRow(icon: "bell.badge.fill", iconTint: .yellow,
                        title: "GT R build slots", subtitle: "Notify when a slot opens",
                        detail: "ON", detailTint: .green)
                DemoRow(icon: "bell.fill", iconTint: .yellow,
                        title: "A110 allocations", subtitle: "Notify on cancellations",
                        detail: "ON", detailTint: .green)
                DemoRow(icon: "bell.slash.fill", iconTint: .white.opacity(0.5),
                        title: "Price changes", subtitle: "Weekly digest",
                        detail: "OFF", detailTint: .white.opacity(0.4))
                DemoRow(image: DemoCar.amg, title: "Back in stock: GT R",
                        subtitle: "Yesterday · 3 build slots left")
            }
            .padding(.top, 24)
        }
    }
}

// MARK: - 7. Video — premiere

private struct PremiereDemoScreen: View {
    var body: some View {
        DemoChrome(accent: Color(red: 1.0, green: 0.27, blue: 0.42),
                   trigger: "Show video",
                   config: InAppDemoConfigs.video) {
            DemoSectionTitle(eyebrow: "Premiere", title: "The reveal")

            ZStack {
                DemoCarImage(url: DemoCar.ferrari, height: 220)
                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 74, height: 74)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: 2)
                    )
                    .background(Circle().fill(.ultraThinMaterial))
                    .clipShape(Circle())
            }
            .padding(.top, 24)

            Text("Live from the studio")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 18)

            Text("Watch it move before anyone else. The full film drops here the moment the covers come off.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(4)
                .padding(.top, 8)
        }
    }
}

// MARK: - 8. PiP — configurator

private struct ConfiguratorDemoScreen: View {
    private let paints: [Color] = [
        Color(red: 0.75, green: 0.09, blue: 0.15),
        Color(red: 0.11, green: 0.13, blue: 0.18),
        Color(red: 0.82, green: 0.82, blue: 0.84),
        Color(red: 0.05, green: 0.32, blue: 0.24),
    ]

    var body: some View {
        DemoChrome(accent: .cyan,
                   trigger: "Show PiP",
                   config: InAppDemoConfigs.pip) {
            DemoSectionTitle(eyebrow: "Configurator", title: "Build your A110")

            DemoCarImage(url: DemoCar.alpine, height: 190)
                .padding(.top, 24)

            VStack(alignment: .leading, spacing: 12) {
                Text("Exterior paint")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 14) {
                    ForEach(Array(paints.enumerated()), id: \.offset) { index, paint in
                        Circle()
                            .fill(paint)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle().strokeBorder(
                                    index == 0 ? Color.cyan : .white.opacity(0.15),
                                    lineWidth: index == 0 ? 2.5 : 1
                                )
                            )
                    }
                    Spacer()
                }
            }
            .padding(.top, 24)

            VStack(spacing: 12) {
                DemoRow(icon: "circle.grid.cross.fill", iconTint: .cyan,
                        title: "Wheels", subtitle: "10-spoke forged magnesium",
                        detail: "+$8,000", detailTint: .white.opacity(0.7))
                DemoRow(icon: "chair.lounge.fill", iconTint: .cyan,
                        title: "Interior", subtitle: "Alcantara, contrast stitch",
                        detail: "+$4,500", detailTint: .white.opacity(0.7))
            }
            .padding(.top, 20)

            Text("Keep configuring while the film floats — the PiP lives in its own window.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .padding(.top, 18)
        }
    }
}

// MARK: - 10. Scratch card — loyalty reward

private struct ScratchRewardDemoScreen: View {
    var body: some View {
        DemoChrome(accent: .yellow,
                   trigger: "Scratch & Win",
                   config: InAppDemoConfigs.scratchCard) {
            DemoSectionTitle(eyebrow: "Rewards", title: "Member perks")

            VStack(spacing: 14) {
                DemoRow(image: DemoCar.amg, title: "Apex Club",
                        subtitle: "Gold tier — 2,450 points", detail: "GOLD", detailTint: .yellow)
                DemoRow(image: DemoCar.alpine, title: "This week's perk",
                        subtitle: "A scratch card is waiting for you", detail: "NEW", detailTint: .orange)
                DemoRow(image: DemoCar.ferrari, title: "Referral bonus",
                        subtitle: "Invite a friend — both get detailing")
            }
            .padding(.top, 20)

            Text("The prize and promo code come from the campaign — the client only plays the reveal.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .padding(.top, 18)
        }
    }
}

// MARK: - 11. Spin wheel — garage perks

private struct SpinWheelDemoScreen: View {
    var body: some View {
        DemoChrome(accent: .purple,
                   trigger: "Spin the Wheel",
                   config: InAppDemoConfigs.spinWheel) {
            DemoSectionTitle(eyebrow: "Rewards", title: "Weekly wheel")

            VStack(spacing: 14) {
                DemoRow(image: DemoCar.ferrari, title: "One spin, six perks",
                        subtitle: "Every slice wins something this week", detail: "LIVE", detailTint: .purple)
                DemoRow(image: DemoCar.amg, title: "Last week's winner",
                        subtitle: "M. Weber took the track day")
                DemoRow(image: DemoCar.alpine, title: "Terms",
                        subtitle: "One spin per member per week")
            }
            .padding(.top, 20)

            Text("The wheel decelerates onto the campaign-chosen segment — with haptic ticks on every boundary.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .padding(.top, 18)
        }
    }
}

// MARK: - Demo configs (mirror the backend `data` payload)

enum InAppDemoConfigs {

    // MARK: - Contract helpers
    // The strict parser requires text as {text,color}, buttons as
    // {text:{text,color}, background, border:{color,radius}, action}, and an action
    // object. These builders keep every demo config valid against that contract.

    private static func txt(_ text: String, _ color: String) -> [AnyHashable: Any] {
        ["text": text, "color": color]
    }

    private static let urlAction: [AnyHashable: Any] = ["type": "url", "url": "pushwoosh://sale"]
    private static let closeAction: [AnyHashable: Any] = ["type": "close"]

    private static func button(_ text: String, textColor: String, background: String,
                               border: String, radius: Int = 12,
                               action: [AnyHashable: Any]) -> [AnyHashable: Any] {
        ["text": txt(text, textColor), "background": background,
         "border": ["color": border, "radius": radius], "action": action]
    }

    /// Action-less button (spin/reveal/spin-button) — same shape, no action key.
    private static func plainButton(_ text: String, textColor: String, background: String,
                                    border: String, radius: Int = 12) -> [AnyHashable: Any] {
        ["text": txt(text, textColor), "background": background,
         "border": ["color": border, "radius": radius]]
    }

    static let modal: [AnyHashable: Any] = [
        "displayType": "modal",
        "inAppId": "sample_modal",
        "modal": [
            "background": "#FFFFFF",
            "title": txt("The GT R has landed", "#111111"),
            "message": txt("585 hp of Affalterbach engineering — now in the showroom.", "#555555"),
            "image": DemoCar.amg.absoluteString,
            "showClose": true,
            "dimBackground": true,
            "buttons": [
                button("Book a test drive", textColor: "#FFFFFF", background: "#FF3B30",
                       border: "#FF3B30", action: urlAction),
                button("Maybe later", textColor: "#8A8A8E", background: "#EFEFF4",
                       border: "#EFEFF4", action: closeAction)
            ]
        ]
    ]

    // MARK: - Image handling · one demo per display type (modal / fullscreen / stories)

    /// Modal — a 1:1 square image (Braze's recommended modal ratio) + title, copy and buttons.
    static let imageModalDemo: [AnyHashable: Any] = [
        "displayType": "modal",
        "inAppId": "sample_image_modal",
        "modal": [
            "background": "#FFFFFF",
            "image": DemoCar.imageModal.absoluteString,
            "title": txt("New arrival", "#111111"),
            "message": txt("The 2026 flagship just landed — book your test drive today.", "#555555"),
            "showClose": true,
            "dimBackground": true,
            "buttons": [
                button("Shop now", textColor: "#FFFFFF", background: "#FF3B30", border: "#FF3B30", action: urlAction),
                button("Later", textColor: "#8A8A8E", background: "#EFEFF4", border: "#EFEFF4", action: closeAction)
            ]
        ]
    ]

    /// Modal with an ordinary 3:4 portrait — the well takes the real ratio and shows it whole, full width.
    static let imageModalPortraitDemo: [AnyHashable: Any] = [
        "displayType": "modal",
        "inAppId": "sample_image_modal_portrait",
        "modal": [
            "background": "#FFFFFF",
            "image": DemoCar.imageModalPortrait.absoluteString,
            "title": txt("Portrait source · 3:4", "#111111"),
            "message": txt("A normal portrait photo: the card grows to the image's own ratio, full width, no crop and no side bars.", "#555555"),
            "showClose": true,
            "dimBackground": true,
            "buttons": [
                button("Shop now", textColor: "#FFFFFF", background: "#FF3B30", border: "#FF3B30", action: urlAction),
                button("Later", textColor: "#8A8A8E", background: "#EFEFF4", border: "#EFEFF4", action: closeAction)
            ]
        ]
    ]

    /// Modal with a very tall 1:4 image — taller than the safe-area cap, so it is scaled down whole.
    static let imageModalTallDemo: [AnyHashable: Any] = [
        "displayType": "modal",
        "inAppId": "sample_image_modal_tall",
        "modal": [
            "background": "#FFFFFF",
            "image": DemoCar.imageModalTall.absoluteString,
            "title": txt("Tall source · 1:4", "#111111"),
            "message": txt("Taller than the card can grow — the well stops at the safe-area cap and the whole image is scaled down inside it.", "#555555"),
            "showClose": true,
            "dimBackground": true,
            "buttons": [
                button("Got it", textColor: "#FFFFFF", background: "#FF3B30", border: "#FF3B30", action: closeAction)
            ]
        ]
    ]

    /// Full-screen — a 9:16 portrait fills the whole screen (cover), overlaid title, copy and buttons.
    static let imageFullscreenDemo: [AnyHashable: Any] = [
        "displayType": "fullscreen",
        "inAppId": "sample_image_fullscreen",
        "fullscreen": [
            "cover": ["background": "#111111", "image": DemoCar.imageFullscreen.absoluteString],
            "title": txt("The 2026 lineup", "#FFFFFF"),
            "message": txt("Six new arrivals. Reserve your test drive today.", "#EBEBEB"),
            "showClose": true,
            "buttons": [
                button("Reserve", textColor: "#FFFFFF", background: "#FF3B30", border: "#FF3B30", action: urlAction),
                button("Not now", textColor: "#FFFFFF", background: "#3A3A3C", border: "#3A3A3C", action: closeAction)
            ]
        ]
    ]

    /// Stories — three 9:16 portrait frames, each fills the screen (cover); swipe through.
    static let imageStoriesDemo: [AnyHashable: Any] = [
        "displayType": "stories",
        "inAppId": "sample_image_stories",
        "stories": [
            "showClose": true,
            "loop": false,
            "items": [
                ["image": DemoCar.imageStory1.absoluteString, "title": txt("Showroom", "#FFFFFF"),
                 "message": txt("Now open downtown", "#EBEBEB"), "duration": 4, "buttons": [[AnyHashable: Any]]()],
                ["image": DemoCar.imageStory2.absoluteString, "title": txt("Test drive", "#FFFFFF"),
                 "message": txt("Book any model", "#EBEBEB"), "duration": 4, "buttons": [[AnyHashable: Any]]()],
                ["image": DemoCar.imageStory3.absoluteString, "title": txt("Trade-in", "#FFFFFF"),
                 "message": txt("Get an instant quote", "#EBEBEB"), "duration": 4, "buttons": [[AnyHashable: Any]]()]
            ]
        ]
    ]

    static let sheet: [AnyHashable: Any] = [
        "displayType": "sheet",
        "inAppId": "sample_sheet",
        "sheet": [
            "background": "#FFFFFF",
            "title": txt("Your quote is ready", "#111111"),
            "message": txt("Guaranteed buyout for your A110: $68,500 — valid for 7 days, paperwork on us.", "#555555"),
            "image": DemoCar.alpine.absoluteString,
            "showClose": true,
            "dimBackground": true,
            "buttons": [
                button("Get guaranteed quote", textColor: "#FFFFFF", background: "#0FB07C",
                       border: "#0FB07C", radius: 14, action: urlAction),
                button("Not now", textColor: "#8A8A8E", background: "#EFEFF4",
                       border: "#EFEFF4", radius: 14, action: closeAction)
            ]
        ]
    ]

    static let carousel: [AnyHashable: Any] = [
        "displayType": "carousel",
        "inAppId": "sample_carousel",
        "carousel": [
            "showClose": true,
            "items": [
                ["image": DemoCar.amgPortrait.absoluteString,
                 "title": txt("AMG GT R", "#FFFFFF"),
                 "message": txt("585 hp biturbo V8 — just landed", "#EBEBEB"),
                 "action": ["type": "url", "url": "pushwoosh://product/n6fx"]],
                ["image": DemoCar.alpinePortrait.absoluteString,
                 "title": txt("Alpine A110", "#FFFFFF"),
                 "message": txt("Featherweight icon — limited allocation", "#EBEBEB"),
                 "action": ["type": "url", "url": "pushwoosh://product/x6f"]],
                ["image": DemoCar.ferrariPortrait.absoluteString,
                 "title": txt("Ferrari 458", "#FFFFFF"),
                 "message": txt("Maranello icon — book a viewing", "#EBEBEB"),
                 "action": ["type": "url", "url": "pushwoosh://product/x7f"]]
            ]
        ]
    ]

    static let stories: [AnyHashable: Any] = [
        "displayType": "stories",
        "inAppId": "sample_stories",
        "stories": [
            "showClose": true,
            "loop": false,
            "items": [
                ["image": DemoCar.amgPortrait.absoluteString,
                 "title": txt("AMG GT R", "#FFFFFF"),
                 "message": txt("The Green Hell special", "#EBEBEB"),
                 "duration": 4,
                 "buttons": [button("Configure yours", textColor: "#FFFFFF", background: "#FF3B30",
                                    border: "#FF3B30", action: ["type": "url", "url": "pushwoosh://product/n6fx"])]],
                ["image": DemoCar.alpinePortrait.absoluteString,
                 "title": txt("Alpine A110", "#FFFFFF"),
                 "message": txt("The featherweight legend, reborn", "#EBEBEB"),
                 "duration": 4,
                 "buttons": [button("Reserve now", textColor: "#FFFFFF", background: "#0FB07C",
                                    border: "#0FB07C", action: urlAction)]],
                ["image": DemoCar.ferrariPortrait.absoluteString,
                 "title": txt("Ferrari 458", "#FFFFFF"),
                 "message": txt("Prancing horse, pure theatre", "#EBEBEB"),
                 "duration": 4,
                 "buttons": [button("Explore", textColor: "#FFFFFF", background: "#5856D6",
                                    border: "#5856D6", action: ["type": "url", "url": "pushwoosh://product/x7f"])]]
            ]
        ]
    ]

    static let fullscreen: [AnyHashable: Any] = [
        "displayType": "fullscreen",
        "inAppId": "sample_fullscreen",
        "fullscreen": [
            "cover": ["background": "#111111", "image": DemoCar.ferrariPortrait.absoluteString],
            "title": txt("Pure Maranello", "#FFFFFF"),
            "message": txt("The prancing horse, reimagined. Reserve your allocation before the next drop.", "#EBEBEB"),
            "showClose": true,
            "buttons": [
                button("Reserve now", textColor: "#FFFFFF", background: "#FF3B30",
                       border: "#FF3B30", action: urlAction),
                button("Not now", textColor: "#FFFFFF", background: "#3A3A3C",
                       border: "#3A3A3C", action: closeAction)
            ]
        ]
    ]

    static let bannerBottom: [AnyHashable: Any] = [
        "displayType": "banner",
        "inAppId": "sample_banner",
        "banner": [
            "position": "bottom",
            "background": "#1C1C1E",
            "image": DemoCar.alpine.absoluteString,
            "title": txt("Alpine A110 just dropped", "#FFFFFF"),
            "message": txt("The featherweight icon — tap to see the build", "#EBEBEB"),
            "autoDismiss": 6,
            "showClose": true,
            "action": ["type": "url", "url": "pushwoosh://product/x6f"]
        ]
    ]

    static let bannerTop: [AnyHashable: Any] = [
        "displayType": "banner",
        "inAppId": "sample_banner_top",
        "banner": [
            "position": "top",
            "background": "#1C1C1E",
            "image": DemoCar.amg.absoluteString,
            "title": txt("Back in stock: GT R", "#FFFFFF"),
            "message": txt("Only 3 build slots left this quarter", "#EBEBEB"),
            "autoDismiss": 6,
            "showClose": true,
            "action": ["type": "url", "url": "pushwoosh://product/n6fx"]
        ]
    ]

    // Free Pexels stock clip (cars on the highway) — swap for the real campaign video.
    static let video: [AnyHashable: Any] = [
        "displayType": "video",
        "inAppId": "sample_video",
        "video": [
            "url": "https://videos.pexels.com/video-files/854745/854745-hd_1280_720_50fps.mp4",
            "poster": DemoCar.ferrariPortrait.absoluteString,
            "title": txt("The reveal", "#FFFFFF"),
            "message": txt("Watch it move before anyone else.", "#EBEBEB"),
            "loop": true,
            "muted": true,
            "showClose": true,
            "buttons": [
                button("Shop the lineup", textColor: "#FFFFFF", background: "#FF3B30",
                       border: "#FF3B30", action: urlAction)
            ]
        ]
    ]

    static let pip: [AnyHashable: Any] = [
        "displayType": "pip",
        "inAppId": "sample_pip",
        "pip": [
            "url": "https://videos.pexels.com/video-files/854745/854745-hd_1280_720_50fps.mp4",
            "poster": DemoCar.alpine.absoluteString,
            "position": "bottom-right",
            "width": 40,
            "aspectRatio": 0.5625,
            "loop": true,
            "muted": true,
            "showClose": true,
            "action": ["type": "url", "url": "pushwoosh://product/x6f"]
        ]
    ]

    static let scratchCard: [AnyHashable: Any] = [
        "displayType": "scratchcard",
        "inAppId": "sample_scratch",
        "scratchcard": [
            "background": ["#3A1C71", "#B3227C", "#E0503A"],
            "title": txt("Your loyalty reward", "#FFFFFF"),
            "message": txt("Scratch the foil to reveal this week's garage perk.", "#F2DFF5"),
            "cover": ["background": "#C9CDD6"],
            "revealThreshold": 0.55,
            "revealButton": plainButton("Reveal without scratching", textColor: "#FFFFFF",
                                        background: "#00000033", border: "#FFFFFF66"),
            "showClose": true,
            "reward": [
                "title": txt("20% off detailing", "#111111"),
                "message": txt("Valid for any full-detail booking this month.", "#555555"),
                "code": "APEX20",
                "button": button("Book detailing", textColor: "#FFFFFF", background: "#B3227C",
                                 border: "#B3227C", action: ["type": "url", "url": "pushwoosh://detailing"])
            ]
        ]
    ]

    static let spinWheel: [AnyHashable: Any] = [
        "displayType": "spinwheel",
        "inAppId": "sample_wheel",
        "spinwheel": [
            "background": ["#1B1B46", "#5B2B8F", "#B0338A"],
            "title": txt("Spin for a garage perk", "#FFFFFF"),
            "message": txt("One spin — every slice wins this week.", "#E3D9F2"),
            "spinButton": plainButton("SPIN", textColor: "#1B1B46", background: "#F2C94C", border: "#F2C94C"),
            "winIndex": 2,
            "showClose": true,
            "segments": [
                ["message": txt("5% off", "#FFFFFF"), "color": "#5856D6", "weight": 1],
                ["message": txt("Free wash", "#FFFFFF"), "color": "#FF2D55", "weight": 1],
                ["message": txt("20% off", "#FFFFFF"), "color": "#30B0C7", "weight": 1,
                 "reward": [
                    "title": txt("20% off your next service", "#FFFFFF"),
                    "message": txt("Applies to any service booked within 30 days.", "#E3D9F2"),
                    "code": "SPIN20",
                    "button": button("Claim service deal", textColor: "#1B1B46", background: "#F2C94C",
                                     border: "#F2C94C", action: ["type": "url", "url": "pushwoosh://service"])
                 ]],
                ["message": txt("Track day", "#FFFFFF"), "color": "#FF9500", "weight": 1],
                ["message": txt("10% off", "#FFFFFF"), "color": "#AF52DE", "weight": 1],
                ["message": txt("Floor mats", "#FFFFFF"), "color": "#34C759", "weight": 1]
            ],
            "reward": [
                "title": txt("You won a garage perk!", "#FFFFFF"),
                "code": "APEXPERK",
                "button": button("Claim", textColor: "#1B1B46", background: "#F2C94C",
                                 border: "#F2C94C", action: urlAction)
            ]
        ]
    ]
}

#Preview {
    InAppDemoScreenView(screen: .modal)
}
