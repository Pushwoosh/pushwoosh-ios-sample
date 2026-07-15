//
//  DeepLinkRouter.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI

// Routes a push's custom data into the app. A campaign can carry, in the push
// custom data (the `u` field), keys like:
//   { "product_id": "chrono" }   -> opens that product
//   { "voucher": "SAVE20" }      -> shows a voucher
//   { "sale": true }             -> opens the sale screen
// AppDelegate feeds message.customData (on tap) and getLaunchNotification() (cold
// start) into route(_:); ContentView presents whatever gets set.
struct Voucher: Identifiable { let id: String; var code: String { id } }

final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    @Published var product: Product?
    @Published var voucher: Voucher?
    @Published var showSale = false

    func route(_ raw: [AnyHashable: Any]?) {
        guard let data = Self.customData(from: raw) else { return }
        if let code = (data["voucher"] as? String), !code.isEmpty {
            voucher = Voucher(id: code)
        } else if let pid = (data["product_id"] as? String), let product = Product.byId[pid] {
            self.product = product
        } else if data["sale"] != nil {
            showSale = true
        }
    }

    // Pushwoosh custom data usually lives under "u" (dict or JSON string); fall back to root.
    private static func customData(from raw: [AnyHashable: Any]?) -> [AnyHashable: Any]? {
        guard let raw else { return nil }
        if let u = raw["u"] as? [AnyHashable: Any] { return u }
        if let s = raw["u"] as? String, let parsed = json(s) { return parsed }
        return raw
    }

    private static func json(_ string: String) -> [AnyHashable: Any]? {
        guard let data = string.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any] else { return nil }
        return obj
    }
}

// Branded voucher screen presented when a push carries a `voucher` code.
struct VoucherView: View {
    let code: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(rgb: 0x2B0A29), Color(rgb: 0xC4185C), Color(rgb: 0xFF8A3D)],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: "ticket.fill").font(.system(size: 56, weight: .bold)).foregroundStyle(.white)
                Text("You've got a voucher").font(PushMart.display(30)).foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Use it at checkout before it expires.").font(PushMart.body(15)).foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 12) {
                    Text(code).font(.system(size: 22, weight: .heavy, design: .monospaced)).foregroundStyle(.white)
                    Button {
                        UIPasteboard.general.string = code
                        withAnimation { copied = true }
                    } label: {
                        Text(copied ? "COPIED" : "COPY").font(PushMart.label(13)).foregroundStyle(Color(rgb: 0xC4185C))
                            .padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(.white))
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.14))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.3), lineWidth: 1)))

                Spacer()
                Button { dismiss() } label: {
                    Text("Shop now").font(PushMart.headline(17)).foregroundStyle(Color(rgb: 0x2B0A29))
                        .frame(maxWidth: .infinity).padding(.vertical, 16).background(Capsule().fill(.white))
                }
                .padding(.horizontal, 28).padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .padding(12).background(Circle().fill(.white.opacity(0.18)))
            }.padding(16)
        }
    }
}
