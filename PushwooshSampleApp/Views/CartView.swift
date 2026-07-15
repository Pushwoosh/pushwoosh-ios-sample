//
//  CartView.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI
import PushwooshFramework

// Shared shopping bag. Checkout fires a Pushwoosh `checkout` event so downstream
// journeys (order-confirmation push, abandoned-cart, etc.) can be triggered.
final class CartStore: ObservableObject {
    static let shared = CartStore()
    @Published private(set) var items: [String: Int] = [:]

    func add(_ product: Product) {
        items[product.id, default: 0] += 1
        syncBadge()
    }
    func setQuantity(_ qty: Int, for id: String) {
        if qty <= 0 { items[id] = nil } else { items[id] = qty }
        syncBadge()
    }
    func clear() {
        items.removeAll()
        syncBadge()
    }

    // Mirror the cart count onto the app icon badge (and sync it to Pushwoosh).
    private func syncBadge() {
        PushwooshHelper.safeCall { Pushwoosh.configure.sendBadges(count) }
    }

    var count: Int { items.values.reduce(0, +) }
    var lines: [(product: Product, qty: Int)] {
        items.compactMap { id, qty in Product.byId[id].map { ($0, qty) } }
             .sorted { $0.product.name < $1.product.name }
    }
    var totalCents: Int {
        items.reduce(0) { $0 + (Product.byId[$1.key]?.priceCents ?? 0) * $1.value }
    }
    var totalText: String { "$" + String(format: "%.2f", Double(totalCents) / 100) }
}

struct CartView: View {
    @ObservedObject private var cart = CartStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var placed = false

    var body: some View {
        ZStack {
            PushMartBackground()
            if placed {
                confirmation
            } else if cart.count == 0 {
                empty
            } else {
                filled
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    .padding(11).background(Circle().fill(.white.opacity(0.16)))
            }.padding(16)
        }
    }

    private var filled: some View {
        VStack(spacing: 0) {
            Text("Your bag").font(PushMart.display(28)).foregroundStyle(PushMart.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading).padding(20)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(cart.lines, id: \.product.id) { line in row(line.product, line.qty) }
                }
                .padding(.horizontal, 20).padding(.bottom, 130)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                HStack {
                    Text("Total").font(PushMart.headline(16)).foregroundStyle(PushMart.textSecondary)
                    Spacer()
                    Text(cart.totalText).font(PushMart.title(22)).foregroundStyle(PushMart.textPrimary)
                }
                PushMartButton(title: "Checkout", icon: "creditcard.fill") { checkout() }
                    .sdkNote("Pushwoosh.configure.sendPurchase(...) + setTags + postEvent",
                             "Placing the order records each purchase, updates segmentation tags, fires the checkout event, starts live order tracking and clears the badge.",
                             docs: "sendPurchase runs once per line item; the two PWTagsBuilder operations are merged into a single setTags call; the Live Activity push token is registered with Pushwoosh asynchronously once ActivityKit issues it; the badge is cleared when the bag is emptied on checkout.",
                             calls: [
                                .init(code: "sendPurchase(id, withPrice: price, currencyCode: \"USD\", andDate: date)",
                                      note: "Per item in the bag: records the product id, its price and the purchase date for revenue and LTV analytics."),
                                .init(code: "PWTagsBuilder.incrementalTag(with: 1)",
                                      note: "Builds the \"orders_placed\" operation: bumps this device's lifetime order count by 1."),
                                .init(code: "PWTagsBuilder.appendValues(toListTag: ids)",
                                      note: "Builds the \"purchased_products\" operation: appends the bought product ids to the list tag without overwriting past purchases."),
                                .init(code: "setTags([\"orders_placed\": ..., \"purchased_products\": ...])",
                                      note: "Sends both tag operations to Pushwoosh in one call for segmentation."),
                                .init(code: "PWInAppManager.shared().postEvent(\"checkout\", withAttributes: [\"items\": count, \"total\": total])",
                                      note: "Fires the checkout event with the item count and order total: triggers journeys and in-app message rules."),
                                .init(code: "Pushwoosh.LiveActivities.startLiveActivity(token: hex, activityId: orderId)",
                                      note: "Starts live order tracking: registers the activity's push token so Pushwoosh can update the order card remotely."),
                                .init(code: "sendBadges(0)",
                                      note: "Clears the app icon badge after the bag is emptied on checkout.")
                             ])
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
        }
    }

    private func row(_ product: Product, _ qty: Int) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [product.tint, product.tint.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                .frame(width: 60, height: 60)
                .overlay(Image(systemName: product.symbol).font(.system(size: 24, weight: .semibold)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 3) {
                Text(product.name).font(PushMart.headline(15)).foregroundStyle(PushMart.textPrimary)
                Text(product.price).font(PushMart.body(14)).foregroundStyle(PushMart.coral)
            }
            Spacer()
            HStack(spacing: 14) {
                stepper("minus") { cart.setQuantity(qty - 1, for: product.id) }
                Text("\(qty)").font(PushMart.headline(15)).foregroundStyle(PushMart.textPrimary).frame(minWidth: 18)
                stepper("plus") { cart.setQuantity(qty + 1, for: product.id) }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).fill(PushMart.surface)
            .overlay(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
        .sdkNote("Pushwoosh.configure.sendBadges(_:)",
                 "Changing an item's quantity syncs the cart count to the app icon badge.",
                 calls: [
                    .init(code: "sendBadges(count)",
                          note: "The +/- steppers change the quantity, which sends the new total cart count to Pushwoosh and sets it as the app icon badge.")
                 ])
    }

    private func stepper(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundStyle(PushMart.textPrimary)
                .frame(width: 30, height: 30).background(Circle().fill(PushMart.surfaceHi))
        }.buttonStyle(.plain)
    }

    private func checkout() {
        let date = Date()
        let ids = cart.lines.map { $0.product.id }

        // Track each purchase (product id + price) for revenue / LTV analytics.
        for line in cart.lines {
            let price = NSDecimalNumber(value: Double(line.product.priceCents) / 100)
            Pushwoosh.configure.sendPurchase(line.product.id, withPrice: price, currencyCode: "USD", andDate: date)
        }

        // Segmentation tags: bump lifetime order count and append bought products to a list tag.
        var tags: [AnyHashable: Any] = [:]
        if let orders = PWTagsBuilder.incrementalTag(with: 1) { tags["orders_placed"] = orders }
        if let bought = PWTagsBuilder.appendValues(toListTag: ids) { tags["purchased_products"] = bought }
        if !tags.isEmpty { Pushwoosh.configure.setTags(tags) }

        // Fire the checkout event for journeys / in-app triggers.
        PWInAppManager.shared().postEvent("checkout", withAttributes: [
            "items": cart.count,
            "total": cart.totalText
        ])

        // Start a live order-tracking activity for this order.
        let orderId = "order-" + String(UUID().uuidString.prefix(5))
        Task { @MainActor in ManualLiveActivityController.shared.startOrder(id: orderId) }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { placed = true }
        cart.clear()
    }

    private var confirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 68)).foregroundStyle(PushMart.success)
            Text("Order placed!").font(PushMart.display(28)).foregroundStyle(PushMart.textPrimary)
            Text("Track it live from the Orders tab.").font(PushMart.body(15)).foregroundStyle(PushMart.textSecondary)
            PushMartButton(title: "Keep shopping") { dismiss() }.padding(.horizontal, 40).padding(.top, 8)
        }
        .padding(30)
    }

    private var empty: some View {
        VStack(spacing: 14) {
            Image(systemName: "bag").font(.system(size: 56)).foregroundStyle(PushMart.textTertiary)
            Text("Your bag is empty").font(PushMart.title(20)).foregroundStyle(PushMart.textPrimary)
            Text("Browse the shop and add something you love.").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(30)
    }
}
