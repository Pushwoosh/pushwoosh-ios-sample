//
//  RootTabView.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI
import PushwooshFramework

enum PushMartTab: Int, CaseIterable {
    case home, shop, orders, inbox, support, profile
    var title: String {
        switch self {
        case .home: return "Home"; case .shop: return "Shop"; case .orders: return "Orders"
        case .inbox: return "Inbox"; case .support: return "Support"; case .profile: return "Profile"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house.fill"; case .shop: return "bag.fill"; case .orders: return "shippingbox.fill"
        case .inbox: return "tray.fill"; case .support: return "bubble.left.and.bubble.right.fill"; case .profile: return "person.fill"
        }
    }
}

// The main shopping experience: five tabs behind a custom branded tab bar.
struct RootTabView: View {
    @State private var tab: PushMartTab = .home
    @StateObject private var inboxUnread = InboxUnreadModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            PushMartBackground()

            Group {
                switch tab {
                case .home:    HomeTabView(goShop: { tab = .shop })
                case .shop:    ShopTabView()
                case .orders:  OrdersTabView()
                case .inbox:   InboxTabView()
                case .support: SupportView()
                case .profile: ProfileTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            PushMartTabBar(selection: $tab, inboxBadge: inboxUnread.count)
        }
        .pushMartResultOverlay()
    }
}

// Tracks the live unread inbox count via PWInbox and badges the Inbox tab.
final class InboxUnreadModel: ObservableObject {
    @Published var count = 0
    private var observer: NSObjectProtocol?

    init() {
        guard !PushwooshHelper.isUITesting else { return }
        PWInbox.unreadMessagesCount { [weak self] count, _ in
            DispatchQueue.main.async { self?.count = max(0, count) }
        }
        observer = PWInbox.addObserverForUnreadMessagesCount { [weak self] count in
            DispatchQueue.main.async { self?.count = Int(count) }
        }
    }

    deinit {
        if let observer { PWInbox.removeObserver(observer) }
    }
}

struct PushMartTabBar: View {
    @Binding var selection: PushMartTab
    var inboxBadge: Int = 0

    var body: some View {
        HStack {
            ForEach(PushMartTab.allCases, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selection = item }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: .semibold))
                            if item == .inbox && inboxBadge > 0 {
                                Text(inboxBadge > 9 ? "9+" : "\(inboxBadge)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(PushMart.ink)
                                    .padding(3)
                                    .background(Circle().fill(PushMart.coral))
                                    .offset(x: 13, y: -8)
                            }
                        }
                        Text(item.title).font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selection == item ? AnyShapeStyle(PushMart.brandHorizontal) : AnyShapeStyle(PushMart.textTertiary))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 6)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(PushMart.stroke).frame(height: 1), alignment: .top)
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Home

struct HomeTabView: View {
    @AppStorage(PushMartStore.userNameKey) private var userName = ""
    var goShop: () -> Void = {}
    @State private var selected: Product?
    @State private var showSale = false
    @State private var toast: String?

    // Each deal fires a real Pushwoosh in-app trigger (postEvent). With the mock
    // server on (Profile ▸ Rich media) the matching rich media presents; otherwise
    // the event still reaches the server exactly as in production.
    private struct Deal: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let tint: Color
        let event: String
    }
    private let deals: [Deal] = [
        .init(title: "Flash sale", subtitle: "Ends tonight", icon: "bolt.fill", tint: PushMart.coral, event: "showRichMedia"),
        .init(title: "Members deal", subtitle: "Extra 15% off", icon: "star.fill", tint: PushMart.tangerine, event: "showRichMediaClient"),
        .init(title: "Bundle & save", subtitle: "Buy 2, get 1", icon: "shippingbox.fill", tint: Color(rgb: 0xAF7BFF), event: "showRichMediaServer")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting).font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                        PushMartWordmark(size: 28)
                    }
                    Spacer()
                    Circle().fill(PushMart.surfaceHi)
                        .frame(width: 42, height: 42)
                        .overlay(Image(systemName: "bell.fill").font(.system(size: 16)).foregroundStyle(PushMart.textSecondary))
                }
                .padding(.top, 8)

                heroCard

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Today's deals")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(deals) { deal in dealCard(deal) }
                        }
                    }
                }
                .sdkNote("PWInAppManager.shared().postEvent(_:)",
                         "Each deal card posts an in-app event; Pushwoosh matches it to a rich-media in-app message.",
                         docs: "Backed by the local mock server when PWMockServerEnabled is set; otherwise the event still reaches Pushwoosh exactly as in production.",
                         calls: [
                            .init(code: "postEvent(\"showRichMedia\")",
                                  note: "Flash sale - presents the campaign's rich media exactly as configured on the dashboard."),
                            .init(code: "postEvent(\"showRichMediaClient\")",
                                  note: "Members deal - same message with client-side style overrides applied through the SDK."),
                            .init(code: "postEvent(\"showRichMediaServer\")",
                                  note: "Bundle & save - style_settings replaced with server-simulated values."),
                         ])

                SectionHeader(title: "Featured", action: "See all", onAction: goShop)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(Product.featured) { p in
                        ProductCard(product: p) { selected = p }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .overlay(alignment: .bottom) { toastView }
        .sheet(item: $selected) { PushMartProductDetail(product: $0) }
        .fullScreenCover(isPresented: $showSale) { SaleView(isPresented: $showSale) }
    }

    private var greeting: String {
        userName.isEmpty ? "Welcome back" : "Hi, \(userName.split(separator: " ").first.map(String.init) ?? userName)"
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous).fill(PushMart.brand)
            Circle().fill(.white.opacity(0.18)).frame(width: 160).offset(x: 120, y: -30)
            VStack(alignment: .leading, spacing: 6) {
                Text("MEMBERS DROP").font(PushMart.label(11)).tracking(2).foregroundStyle(PushMart.ink.opacity(0.7))
                Text("Up to 40% off\nthis week").font(PushMart.display(28)).foregroundStyle(PushMart.ink)
                Text("Shop the drop").font(PushMart.headline(14))
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(Capsule().fill(PushMart.ink)).foregroundStyle(Color.white)
                    .padding(.top, 6)
            }
            .padding(22)
        }
        .frame(height: 190)
        .onTapGesture { showSale = true }
    }

    private func dealCard(_ deal: Deal) -> some View {
        Button {
            PWInAppManager.shared().postEvent(deal.event, withAttributes: [:])
            showToast("“\(deal.title)” unlocked — check your offers")
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: deal.icon).font(.system(size: 20, weight: .bold)).foregroundStyle(deal.tint)
                    .frame(width: 44, height: 44).background(Circle().fill(deal.tint.opacity(0.16)))
                Text(deal.title).font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                Text(deal.subtitle).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
            }
            .padding(16)
            .frame(width: 168, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).fill(PushMart.surface)
                .overlay(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var toastView: some View {
        if let toast {
            Text(toast)
                .font(PushMart.body(13.5)).foregroundStyle(PushMart.textPrimary)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .background(Capsule().fill(PushMart.surfaceHi).overlay(Capsule().strokeBorder(PushMart.stroke, lineWidth: 1)))
                .padding(.bottom, 104)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func showToast(_ text: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation { toast = nil }
        }
    }
}

// MARK: - Shop

struct ShopTabView: View {
    @State private var category = "All"
    @State private var selected: Product?
    @State private var query = ""
    @State private var showCart = false
    @ObservedObject private var cart = CartStore.shared

    private var results: [Product] {
        let base = Product.inCategory(category)
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Shop").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    cartButton
                }
                .padding(.top, 8)

                PushMartField(placeholder: "Search products", text: $query, icon: "magnifyingglass")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Product.categories, id: \.self) { c in
                            Button { withAnimation { category = c } } label: {
                                PushMartChip(title: c, selected: category == c)
                            }.buttonStyle(.plain)
                        }
                    }
                }

                if results.isEmpty {
                    Text("No products match “\(query)”.")
                        .font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                        .frame(maxWidth: .infinity).padding(.top, 40)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(results) { p in
                            ProductCard(product: p) { selected = p }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .dismissKeyboardOnTap()
        .sheet(item: $selected) { PushMartProductDetail(product: $0) }
        .sheet(isPresented: $showCart) { CartView() }
    }

    private var cartButton: some View {
        Button { showCart = true } label: {
            ZStack(alignment: .topTrailing) {
                Circle().fill(PushMart.surfaceHi).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "bag").font(.system(size: 17, weight: .semibold)).foregroundStyle(PushMart.textPrimary))
                if cart.count > 0 {
                    Text("\(cart.count)").font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(PushMart.ink).padding(5)
                        .background(Circle().fill(PushMart.coral)).offset(x: 4, y: -4)
                }
            }
        }.buttonStyle(.plain)
    }
}

struct ProductCard: View {
    let product: Product
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [product.tint.opacity(0.9), product.tint.opacity(0.5)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 130)
                        .overlay(Image(systemName: product.symbol).font(.system(size: 46, weight: .semibold)).foregroundStyle(.white.opacity(0.95)))
                    if let badge = product.badge {
                        Text(badge.uppercased()).font(PushMart.label(10)).tracking(1)
                            .foregroundStyle(PushMart.ink)
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(Capsule().fill(.white)).padding(10)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.brand).font(PushMart.label(11)).foregroundStyle(PushMart.textTertiary)
                    Text(product.name).font(PushMart.headline(15)).foregroundStyle(PushMart.textPrimary).lineLimit(1)
                    Text(product.price).font(PushMart.headline(15)).foregroundStyle(PushMart.coral)
                }
                .padding(.top, 10)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).fill(PushMart.surface)
                .overlay(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }
}

struct PushMartProductDetail: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @State private var added = false

    var body: some View {
        ZStack(alignment: .bottom) {
            PushMart.ink.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(LinearGradient(colors: [product.tint, product.tint.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                        .frame(height: 300)
                        .overlay(Image(systemName: product.symbol).font(.system(size: 96, weight: .semibold)).foregroundStyle(.white))
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.brand.uppercased()).font(PushMart.label(12)).tracking(2).foregroundStyle(product.tint)
                        Text(product.name).font(PushMart.display(28)).foregroundStyle(PushMart.textPrimary)
                        Text(product.price).font(PushMart.title(22)).foregroundStyle(PushMart.coral)
                        Text(product.blurb).font(PushMart.body(15)).foregroundStyle(PushMart.textSecondary)
                            .fixedSize(horizontal: false, vertical: true).padding(.top, 4)
                    }
                    .sdkNote("PWInAppManager.shared().postEvent(_:withAttributes:)",
                             "Opening a product posts a product-opened event so Pushwoosh can trigger browse and abandoned-browse journeys.",
                             calls: [
                                .init(code: "postEvent(\"product-opened\", withAttributes: [\"productId\": product.id])",
                                      note: "Fires when the product detail appears, tagged with the id of the product the shopper viewed.")
                             ])
                }
                .padding(20)
                .padding(.bottom, 110)
            }
            PushMartButton(title: added ? "Added to bag" : "Add to bag · \(product.price)",
                       icon: added ? "checkmark" : "bag.fill") {
                withAnimation { added = true }
                CartStore.shared.add(product)
                PWInAppManager.shared().postEvent("add-to-cart", withAttributes: ["productId": product.id, "price": product.price])
            }
            .sdkNote("PWInAppManager.shared().postEvent(_:withAttributes:)",
                     "Adding to the bag posts an add-to-cart event and syncs the new bag count to the app-icon badge.",
                     calls: [
                        .init(code: "postEvent(\"add-to-cart\", withAttributes: [\"productId\": product.id, \"price\": product.price])",
                              note: "Records the add-to-cart conversion with the product id and its price."),
                        .init(code: "Pushwoosh.configure.sendBadges(count)",
                              note: "Mirrors the updated bag count to Pushwoosh so the app-icon badge stays in sync."),
                     ])
            .padding(20)
        }
        .onAppear {
            PWInAppManager.shared().postEvent("product-opened", withAttributes: ["productId": product.id])
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    .padding(11).background(Circle().fill(.white.opacity(0.16)))
            }.padding(16)
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Orders / Inbox wrappers (content re-skinned in later iterations)

struct OrdersTabView: View {
    var body: some View { LiveActivitiesView() }
}

struct InboxTabView: View {
    var body: some View { InboxKitView() }
}
