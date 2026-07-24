//
//  InAppMessagesView.swift
//  PushwooshSampleApp
//
//  Hub for the native in-app module (PushwooshInApp). Each button opens a
//  themed, full-screen demo page (see InAppDemoScreens.swift) that looks like a
//  real screen of a showroom app; the in-app is then presented over it — the
//  way a campaign lands in production. Configs live in InAppDemoConfigs.
//

import SwiftUI
import PushwooshFramework
import PushwooshInApp

struct InAppMessagesView: View {
    @State private var presentedDemo: InAppDemoScreen?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.20),
                    Color(red: 0.20, green: 0.10, blue: 0.30),
                    Color(red: 0.10, green: 0.16, blue: 0.34)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.pink, .orange],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .frame(width: 96, height: 96)
                        .shadow(color: .pink.opacity(0.45), radius: 24, y: 14)
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("IN-APP")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Every template gets its own themed screen.\nOpen one and trigger the in-app over real\napp content — as a campaign would land.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.65))
                        .lineSpacing(3)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 14) {
                    demoButton(title: "Modal · Showroom",
                               icon: "rectangle.center.inset.filled",
                               colors: [.pink, .orange], screen: .modal)

                    demoButton(title: "Sheet · Trade-in",
                               icon: "rectangle.portrait.bottomhalf.filled",
                               colors: [.mint, .teal], screen: .sheet)

                    demoButton(title: "Carousel · New Arrivals",
                               icon: "rectangle.stack.fill",
                               colors: [.purple, .blue], screen: .carousel)

                    demoButton(title: "Stories · Highlights",
                               icon: "play.rectangle.on.rectangle.fill",
                               colors: [.indigo, .pink], screen: .stories)

                    demoButton(title: "Fullscreen · Collection",
                               icon: "rectangle.inset.filled",
                               colors: [.teal, .green], screen: .fullscreen)

                    demoButton(title: "Bottom Banner · Inventory",
                               icon: "rectangle.bottomhalf.inset.filled",
                               colors: [.orange, .red], screen: .bannerBottom)

                    demoButton(title: "Top Banner · Alerts",
                               icon: "rectangle.tophalf.inset.filled",
                               colors: [.yellow, .orange], screen: .bannerTop)

                    demoButton(title: "Video · Premiere",
                               icon: "play.circle.fill",
                               colors: [.red, .pink], screen: .video)

                    demoButton(title: "PiP · Configurator",
                               icon: "pip.fill",
                               colors: [.blue, .cyan], screen: .pip)

                    demoButton(title: "Scratch Card · Rewards",
                               icon: "hand.draw.fill",
                               colors: [.yellow, .orange], screen: .scratchCard)

                    demoButton(title: "Spin Wheel · Weekly Perk",
                               icon: "arrow.triangle.2.circlepath.circle.fill",
                               colors: [.purple, .pink], screen: .spinWheel)
                }
                .padding(.top, 6)
                .padding(.horizontal, 40)

                VStack(spacing: 12) {
                    Text("IMAGE HANDLING · MODAL / FULLSCREEN / STORIES")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                    Text("One fresh image per display type, at the ratio that type expects.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 20)

                    aspectButton("Modal · square image", InAppDemoConfigs.imageModalDemo, colors: [.pink, .orange])
                    aspectButton("Modal · tall image (crops)", InAppDemoConfigs.imageModalTallDemo, colors: [.gray, .indigo])
                    aspectButton("Fullscreen · portrait image", InAppDemoConfigs.imageFullscreenDemo, colors: [.teal, .green])
                    aspectButton("Stories · portrait frames", InAppDemoConfigs.imageStoriesDemo, colors: [.indigo, .pink])
                }
                .padding(.top, 6)
                .padding(.horizontal, 40)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            }
        }
        .fullScreenCover(item: $presentedDemo) { screen in
            InAppDemoScreenView(screen: screen)
        }
        .onAppear {
            Pushwoosh.inApp.delegate = SampleInAppDelegate.shared
        }
    }

    private func demoButton(title: String,
                            icon: String,
                            colors: [Color],
                            screen: InAppDemoScreen) -> some View {
        Button {
            presentedDemo = screen
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .heavy))
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(
                    LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                )
            )
            .shadow(color: colors.first!.opacity(0.45), radius: 18, y: 10)
        }
    }

    /// Presents a modal in-app directly (over this hub screen) whose only difference is the
    /// source image aspect ratio — for eyeballing how the fixed modal media frame crops each.
    private func aspectButton(_ title: String, _ config: [AnyHashable: Any], colors: [Color]) -> some View {
        Button {
            Pushwoosh.inApp.present(config)
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule().fill(
                        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                    )
                )
                .shadow(color: colors.first!.opacity(0.4), radius: 14, y: 8)
        }
    }
}

// MARK: - Lifecycle / click logger

final class SampleInAppDelegate: NSObject, PWInAppMessageDelegate {
    static let shared = SampleInAppDelegate()

    func pushwooshInAppWillPresent(messageId: String?) {
        print("[InApp] willPresent — \(messageId ?? "nil")")
    }

    func pushwooshInAppDidPresent(messageId: String?) {
        print("[InApp] didPresent — \(messageId ?? "nil")")
    }

    func pushwooshInAppDidClose(messageId: String?) {
        print("[InApp] didClose — \(messageId ?? "nil")")
    }

    func pushwooshInAppClickedAction(url: String, messageId: String?) {
        print("[InApp] clicked \(url) — \(messageId ?? "nil")")
    }

    func pushwooshInAppRewardRevealed(promoCode: String?, messageId: String?) {
        print("[InApp] reward revealed \(promoCode ?? "no code") — \(messageId ?? "nil")")
    }

    func pushwooshInAppRewardClaimed(promoCode: String, messageId: String?) {
        print("[InApp] reward claimed \(promoCode) — \(messageId ?? "nil")")
    }
}

#Preview {
    InAppMessagesView()
}
