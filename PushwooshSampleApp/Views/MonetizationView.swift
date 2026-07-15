//
//  MonetizationView.swift
//  PushMart
//

import SwiftUI

// About PushMart — a shopper-facing "how it works" page. Documentation only:
// no SDK calls here by design.
struct MonetizationView: View {
    private struct Perk: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
    }
    private let perks: [Perk] = [
        .init(icon: "sparkles", title: "Members-only drops", subtitle: "Be first when limited items land."),
        .init(icon: "shippingbox.fill", title: "Live order tracking", subtitle: "Follow every order on your Lock Screen."),
        .init(icon: "gift.fill", title: "Rewards on every order", subtitle: "Earn points as you shop, spend them on perks."),
        .init(icon: "tag.fill", title: "Deals tuned to you", subtitle: "Offers picked from the categories you love.")
    ]

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "How PushMart works")
                        ForEach(perks) { perkRow($0) }
                    }
                    about
                    Text("PushMart · Version 2.0.0")
                        .font(PushMart.body(12)).foregroundStyle(PushMart.textTertiary)
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(PushMart.brand)
                    .frame(width: 84, height: 84)
                    .shadow(color: PushMart.coral.opacity(0.45), radius: 22, y: 12)
                Image(systemName: "bag.fill").font(.system(size: 36, weight: .bold)).foregroundStyle(PushMart.ink)
            }
            PushMartWordmark(size: 34)
            Text("Shop what's next.")
                .font(PushMart.display(28)).foregroundStyle(PushMart.textPrimary)
            Text("Exclusive drops, live order tracking and deals picked just for you — all in one place.")
                .font(PushMart.body(15)).foregroundStyle(PushMart.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private func perkRow(_ perk: Perk) -> some View {
        HStack(spacing: 14) {
            Image(systemName: perk.icon)
                .font(.system(size: 18, weight: .bold)).foregroundStyle(PushMart.coral)
                .frame(width: 46, height: 46).background(Circle().fill(PushMart.coral.opacity(0.14)))
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.title).font(PushMart.headline(16)).foregroundStyle(PushMart.textPrimary)
                Text(perk.subtitle).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).fill(PushMart.surface)
            .overlay(RoundedRectangle(cornerRadius: PushMart.radiusCard, style: .continuous).strokeBorder(PushMart.stroke, lineWidth: 1)))
    }

    private var about: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("About").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                Text("PushMart is a modern shopping app for people who want the good stuff first. We send a little nudge when your order moves, when a drop goes live, or when something you love is back — never spam.")
                    .font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    MonetizationView()
}
