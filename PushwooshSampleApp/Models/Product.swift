//
//  Product.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI

// The PushMart catalog. Products are rendered as premium gradient tiles (SF Symbol
// artwork) so the shop looks intentional and works fully offline — no dependency
// on remote image hosts during review.
struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String
    let category: String
    let priceCents: Int
    let symbol: String
    let tintHex: UInt32
    let blurb: String
    var badge: String? = nil

    var tint: Color { Color(rgb: tintHex) }
    var price: String {
        let dollars = Double(priceCents) / 100
        return "$" + (dollars == dollars.rounded() ? String(format: "%.0f", dollars) : String(format: "%.2f", dollars))
    }

    static let categories = ["All", "Sneakers", "Audio", "Watches", "Bags", "Tech"]

    static let all: [Product] = [
        Product(id: "aeroknit",  name: "AeroKnit Runner",   brand: "PushMart Sport",  category: "Sneakers", priceCents: 12900, symbol: "shoe.fill",              tintHex: 0xFF5A5F, blurb: "Feather-light knit runners with a responsive foam sole built for all-day city miles.", badge: "New"),
        Product(id: "pulsebuds", name: "Pulse Buds Pro",    brand: "PushMart Audio",  category: "Audio",    priceCents: 18900, symbol: "airpodspro",            tintHex: 0xFF8A3D, blurb: "Adaptive noise cancellation and spatial audio in a pocket-sized charging case."),
        Product(id: "chrono",    name: "Chrono S3",         brand: "PushMart Time",   category: "Watches",  priceCents: 24900, symbol: "applewatch",            tintHex: 0x5AC8FA, blurb: "A titanium smartwatch with a always-on display and 3-day battery.", badge: "Drop"),
        Product(id: "voyager",   name: "Voyager Tote",      brand: "PushMart Goods",  category: "Bags",     priceCents: 15900, symbol: "bag.fill",             tintHex: 0xAF7BFF, blurb: "Water-resistant everyday tote with a padded 16-inch laptop sleeve."),
        Product(id: "beacon",    name: "Beacon Speaker",    brand: "PushMart Audio",  category: "Audio",    priceCents: 9900,  symbol: "hifispeaker.fill",       tintHex: 0x2BD98A, blurb: "Room-filling 360° sound in a rugged, splash-proof body."),
        Product(id: "glide",     name: "Glide Low",         brand: "PushMart Sport",  category: "Sneakers", priceCents: 10900, symbol: "figure.walk",           tintHex: 0xFFC24B, blurb: "Minimal court-inspired silhouette in a clean monochrome leather."),
        Product(id: "orbit",     name: "Orbit Charger",     brand: "PushMart Tech",   category: "Tech",     priceCents: 4900,  symbol: "bolt.fill",             tintHex: 0xFF4D5E, blurb: "Fast 3-in-1 wireless charging pad for phone, watch and buds.", badge: "Deal"),
        Product(id: "lumen",     name: "Lumen Frames",      brand: "PushMart Tech",   category: "Tech",     priceCents: 21900, symbol: "eyeglasses",            tintHex: 0x64D2FF, blurb: "Smart audio glasses with open-ear speakers and a discreet mic."),
        Product(id: "trail",     name: "Trail Pack 24L",    brand: "PushMart Goods",  category: "Bags",     priceCents: 13900, symbol: "backpack.fill",         tintHex: 0x30D158, blurb: "Weatherproof daypack with a ventilated back panel and rain cover."),
        Product(id: "solo",      name: "Solo Field Watch",  brand: "PushMart Time",   category: "Watches",  priceCents: 17900, symbol: "clock.fill",            tintHex: 0xFF9F0A, blurb: "Analog field watch with a sapphire crystal and 100m water resistance.")
    ]

    static var featured: [Product] { Array(all.prefix(6)) }

    static let byId: [String: Product] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func inCategory(_ category: String) -> [Product] {
        category == "All" ? all : all.filter { $0.category == category }
    }
}
