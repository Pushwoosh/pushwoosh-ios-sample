//
//  ContentView.swift
//  PushwooshSampleApp
//

import SwiftUI

struct ContentView: View {
    @State private var showSale = false
    @State private var presentedGuitar: Guitar?
    @ObservedObject private var router = DeepLinkRouter.shared

    var body: some View {
        RootTabView()
        .fullScreenCover(isPresented: $showSale) {
            SaleView(isPresented: $showSale)
        }
        .fullScreenCover(item: $presentedGuitar) { guitar in
            ProductView(guitar: guitar)
        }
        .sheet(item: $router.product) { product in
            PushMartProductDetail(product: product)
        }
        .fullScreenCover(item: $router.voucher) { voucher in
            VoucherView(code: voucher.code)
        }
        .onChange(of: router.showSale) { _, active in
            if active { showSale = true; router.showSale = false }
        }
        .onOpenURL { url in
            guard url.scheme == "pushwoosh" else { return }
            switch url.host {
            case "sale":
                showSale = true
            case "product":
                if let guitar = Guitar.catalog[url.lastPathComponent] {
                    presentedGuitar = guitar
                }
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Deep-link destination (pushwoosh://sale)

struct SaleView: View {
    @Binding var isPresented: Bool

    @State private var appeared = false
    @State private var glow = false
    @State private var copied = false

    private let promoCode = "STORIES70"

    var body: some View {
        ZStack {
            background
            content
            closeButton
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { glow = true }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x2B0A29), Color(hex: 0xC4185C), Color(hex: 0xFF5E3A)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color(hex: 0xFF8A3D).opacity(0.55))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -110, y: glow ? -300 : -250)
            Circle()
                .fill(Color(hex: 0xFF2D6E).opacity(0.5))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: 130, y: glow ? 320 : 360)
        }
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("LIMITED · 48 HOURS ONLY")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(2.5)
                .foregroundColor(.white.opacity(0.85))
                .reveal(appeared, delay: 0.05)

            Text("SUMMER\nSALE")
                .font(.system(size: 66, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(-6)
                .padding(.top, 8)
                .reveal(appeared, delay: 0.12)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("−70%")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: 0xFFE6A0), .white],
                                       startPoint: .top, endPoint: .bottom)
                    )
                Text("OFF\nEVERYTHING")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.top, 16)
            .reveal(appeared, delay: 0.18)

            promoChip
                .padding(.top, 28)
                .reveal(appeared, delay: 0.24)

            cta
                .padding(.top, 20)
                .reveal(appeared, delay: 0.30)

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var promoChip: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("PROMO CODE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.65))
                Text(promoCode)
                    .font(.system(size: 19, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = promoCode
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { copied = true }
            } label: {
                Text(copied ? "COPIED ✓" : "COPY")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0xC4185C))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(.white))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var cta: some View {
        Button {
            isPresented = false
        } label: {
            HStack(spacing: 10) {
                Text("Shop the drop")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(Color(hex: 0x2B0A29))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Capsule().fill(.white))
            .shadow(color: .black.opacity(0.28), radius: 18, x: 0, y: 10)
        }
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(.white.opacity(0.18)))
                        .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

private extension View {
    func reveal(_ appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 26)
            .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(delay), value: appeared)
    }
}

fileprivate extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - Deep-link destination (pushwoosh://product/<id>)

struct Guitar: Identifiable {
    let id: String
    let series: String
    let name: String
    let priceText: String
    let imageURL: URL
    let specs: [String]
    let blurb: String
    let accent: Color

    static let catalog: [String: Guitar] = [
        "n6fx": Guitar(
            id: "n6fx",
            series: "N · SERIES",
            name: "N6FX Coral",
            priceText: "$1,199",
            imageURL: URL(string: "https://legatorguitars.com/cdn/shop/files/N6FX.Coral.Side.site_1200x1200.png?v=1768604703")!,
            specs: ["6-String", "Multiscale 25.5–27\"", "Roasted Maple", "Fluence Pickups"],
            blurb: "Ergonomic multiscale build with a roasted maple neck and stainless frets — engineered for fast, articulate playing across the entire range.",
            accent: Color(hex: 0xFF6F61)
        ),
        "x6f": Guitar(
            id: "x6f",
            series: "X · SERIES",
            name: "X6F Magma",
            priceText: "$1,099",
            imageURL: URL(string: "https://legatorguitars.com/cdn/shop/files/x6f.magma.front.site.1_1200x1200.png?v=1768853615")!,
            specs: ["6-String", "25.5\" Scale", "Ebony Fretboard", "Hot Output"],
            blurb: "A molten magma finish over a deeply contoured body. Tight low end, singing highs, and a neck profile built for speed.",
            accent: Color(hex: 0xFF3B14)
        ),
        "x7f": Guitar(
            id: "x7f",
            series: "X · SERIES",
            name: "X7F Coral",
            priceText: "$1,299",
            imageURL: URL(string: "https://legatorguitars.com/cdn/shop/files/x7f.coral.front_1024x1024.png?v=1768607405")!,
            specs: ["7-String", "Multiscale", "Stainless Frets", "Extended Range"],
            blurb: "Seven strings of extended-range firepower. Multiscale geometry keeps the low B tight while the highs stay crystal clear.",
            accent: Color(hex: 0xE0457B)
        )
    ]
}

struct ProductView: View {
    let guitar: Guitar
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false
    @State private var glow = false
    @State private var added = false

    var body: some View {
        ZStack(alignment: .bottom) {
            background
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    hero.padding(.top, 6)
                    info
                    Color.clear.frame(height: 130)
                }
                .padding(.horizontal, 24)
            }
            bottomScrim
            cta
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { glow = true }
        }
    }

    private var background: some View {
        ZStack {
            Color(hex: 0x0C0C0F)
            Circle()
                .fill(guitar.accent.opacity(0.45))
                .frame(width: 380, height: 380)
                .blur(radius: 110)
                .offset(x: glow ? 90 : 130, y: glow ? -270 : -310)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            circleButton("chevron.left") { dismiss() }
            Spacer()
            Text("LEGATOR")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .tracking(4)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            circleButton("bag") {}
        }
        .padding(.top, 8)
        .reveal(appeared, delay: 0)
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(Circle().fill(.white.opacity(0.1)))
                .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        }
    }

    private var hero: some View {
        ZStack {
            Text(String(guitar.name.prefix(1)))
                .font(.system(size: 260, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.05))

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(hex: 0xF7F7F5), Color(hex: 0xEAEAE6)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    AsyncImage(url: guitar.imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit().padding(18)
                        case .failure:
                            Image(systemName: "guitars.fill")
                                .font(.system(size: 64))
                                .foregroundColor(guitar.accent)
                        default:
                            ProgressView().tint(guitar.accent)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .frame(height: 360)
                .shadow(color: guitar.accent.opacity(0.35), radius: 32, y: 18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 372)
        .clipped()
        .reveal(appeared, delay: 0.05)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(guitar.series)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundColor(guitar.accent)
                .padding(.top, 24)
                .reveal(appeared, delay: 0.12)

            Text(guitar.name)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 6)
                .reveal(appeared, delay: 0.16)

            Text(guitar.priceText)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .padding(.top, 8)
                .reveal(appeared, delay: 0.2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(guitar.specs, id: \.self) { spec in
                        Text(spec)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(.white.opacity(0.08))
                                    .overlay(Capsule().strokeBorder(guitar.accent.opacity(0.5), lineWidth: 1))
                            )
                    }
                }
            }
            .padding(.top, 20)
            .reveal(appeared, delay: 0.24)

            Text(guitar.blurb)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(4)
                .padding(.top, 22)
                .reveal(appeared, delay: 0.28)
        }
    }

    private var bottomScrim: some View {
        LinearGradient(colors: [Color(hex: 0x0C0C0F).opacity(0), Color(hex: 0x0C0C0F)],
                       startPoint: .top, endPoint: .bottom)
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }

    private var cta: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { added = true }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: added ? "checkmark" : "bag.fill")
                    .font(.system(size: 16, weight: .bold))
                Text(added ? "Added to cart" : "Add to cart · \(guitar.priceText)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: added ? [Color(hex: 0x2BB673), Color(hex: 0x1E9E63)]
                                      : [guitar.accent, guitar.accent.opacity(0.72)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
            )
            .shadow(color: (added ? Color(hex: 0x2BB673) : guitar.accent).opacity(0.4), radius: 20, y: 10)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }
}
