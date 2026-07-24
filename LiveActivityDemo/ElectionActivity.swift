//
//  ElectionActivity.swift
//  LiveActivityDemo
//
//  Created by André Kis on 20.07.26.
//
//  Election results tracker Live Activity in a US-election "tug-of-war" style.
//  The Lock Screen stacks three head-to-head bars: one large bar for the two
//  front-runners (round leader photos flanking big seat counts) and two compact
//  bars underneath for the next party pairs by rank. Each bar fills from both
//  edges toward a central majority marker, the two party colours meeting at a
//  boundary that shows who is ahead. Party colours arrive as hex strings in the
//  ContentState (partyColour / partyColour1) and become a per-party gradient at
//  render time. A party "logo" is used as an asset-catalog image name: when the
//  asset exists (e.g. leader_netanyahu) it renders as a circular photo, otherwise
//  it falls back to the party initials on a gradient badge.
//

import ActivityKit
import WidgetKit
import SwiftUI
import PushwooshLiveActivities

private let electionInk = Color(red: 0.05, green: 0.06, blue: 0.10)
private let electionGold = Color(red: 1.0, green: 0.78, blue: 0.30)

@available(iOS 16.1, *)
struct ElectionActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ElectionAttributes.self) { context in
            ElectionLockScreenView(context: context)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let ranked = context.state.rankedParties
            let leader = ranked.first
            let challenger = ranked.dropFirst().first
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if let challenger {
                        HStack(spacing: 6) {
                            LeaderAvatar(party: challenger, size: 30)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(challenger.name)
                                    .font(.system(size: 13, weight: .heavy, design: .default))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Text(challenger.seatCount)
                                    .font(.system(size: 20, weight: .black, design: .default))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let leader {
                        HStack(spacing: 6) {
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(leader.name)
                                    .font(.system(size: 13, weight: .heavy, design: .default))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Text(leader.seatCount)
                                    .font(.system(size: 20, weight: .black, design: .default))
                                    .foregroundStyle(.white)
                            }
                            LeaderAvatar(party: leader, size: 30)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.majorityStatus)
                        .font(.system(size: 11, weight: .semibold, design: .default))
                        .foregroundStyle(context.majorityReached ? electionGold : .white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let leader, let challenger {
                        VStack(spacing: 3) {
                            DivergentBar(left: challenger, right: leader, height: 10)
                            Text("רוב \(context.state.halfwayCount)")
                                .font(.system(size: 9, weight: .bold, design: .default))
                                .foregroundStyle(electionGold.opacity(0.9))
                                .lineLimit(1)
                        }
                        .padding(.top, 2)
                        .padding(.horizontal, 4)
                    }
                }
            } compactLeading: {
                if let leader {
                    LeaderAvatar(party: leader, size: 18)
                }
            } compactTrailing: {
                if let leader {
                    Text(leader.seatCount)
                        .font(.system(size: 14, weight: .black, design: .default))
                        .foregroundStyle(.white)
                }
            } minimal: {
                if let leader {
                    Text(leader.seatCount)
                        .font(.system(size: 12, weight: .black, design: .default))
                        .foregroundStyle(Color(electionHex: leader.partyColour))
                }
            }
            .keylineTint(electionGold)
        }
    }
}

@available(iOS 16.1, *)
struct ElectionLockScreenView: View {
    let context: ActivityViewContext<ElectionAttributes>

    var body: some View {
        let ranked = context.state.rankedParties
        let top = Array(ranked.prefix(2))
        let miniPairs = context.state.miniPairs
        let target = context.state.targetCount
        let majority = context.state.halfwayCount

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(context.attributes.electionName.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .default))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                Spacer()
                Text("\(target) מנדטים · רוב \(majority)")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }

            if top.count == 2 {
                let left = top[0], right = top[1]
                HStack(alignment: .center, spacing: 8) {
                    LeaderAvatar(party: left, size: 38)
                    Text(left.seatCount)
                        .font(.system(size: 30, weight: .black, design: .default))
                        .foregroundStyle(.white)
                    Spacer(minLength: 6)
                    Text(right.seatCount)
                        .font(.system(size: 30, weight: .black, design: .default))
                        .foregroundStyle(.white)
                    LeaderAvatar(party: right, size: 38)
                }

                DivergentBar(left: left, right: right, height: 11)

                HStack {
                    Text(left.name)
                        .foregroundStyle(Color(electionHex: left.partyColour1))
                    Spacer()
                    Text(right.name)
                        .foregroundStyle(Color(electionHex: right.partyColour1))
                }
                .font(.system(size: 12, weight: .bold, design: .default))
                .lineLimit(1)
            } else if let solo = top.first {
                HStack(spacing: 10) {
                    LeaderAvatar(party: solo, size: 38)
                    Text(solo.name)
                        .font(.system(size: 15, weight: .heavy, design: .default))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(solo.seatCount)
                        .font(.system(size: 28, weight: .black, design: .default))
                        .foregroundStyle(.white)
                }
            }

            if !miniPairs.isEmpty {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(Array(miniPairs.enumerated()), id: \.offset) { item in
                        MiniHeadToHead(left: item.element.0, right: item.element.1)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 2)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(
            ZStack {
                electionInk
                LinearGradient(colors: [electionGold.opacity(0.08), .clear],
                               startPoint: .topTrailing, endPoint: .bottomLeading)
            }
        )
    }
}

// MARK: - Building blocks

@available(iOS 16.1, *)
private struct LeaderAvatar: View {
    let party: Party
    let size: CGFloat

    // Which parties ship a real leader photo. Checked against a known set rather
    // than UIImage(named:), which returns nil inside a widget extension even when
    // the asset IS bundled; SwiftUI's Image(_:) resolves the asset catalog fine.
    private static let photoAssets: Set<String> = ["leader_netanyahu", "leader_eisenkot"]

    var body: some View {
        if Self.photoAssets.contains(party.logo) {
            Image(party.logo)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(Color(electionHex: party.partyColour),
                                          lineWidth: max(1.5, size * 0.05))
                )
        } else {
            PartyBadge(party: party, size: size)
        }
    }
}

@available(iOS 16.1, *)
private struct PartyBadge: View {
    let party: Party
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(electionHex: party.partyColour), Color(electionHex: party.partyColour1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(party.initials)
                    .font(.system(size: size * 0.38, weight: .black, design: .default))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
    }
}

@available(iOS 16.1, *)
private struct MiniHeadToHead: View {
    let left: Party
    let right: Party

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(left.seatCount)
                    .font(.system(size: 16, weight: .black, design: .default))
                    .foregroundStyle(.white)
                Spacer(minLength: 4)
                Text(right.seatCount)
                    .font(.system(size: 16, weight: .black, design: .default))
                    .foregroundStyle(.white)
            }
            DivergentBar(left: left, right: right, height: 5)
            HStack {
                Text(left.name)
                    .foregroundStyle(Color(electionHex: left.partyColour1))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 4)
                Text(right.name)
                    .foregroundStyle(Color(electionHex: right.partyColour1))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.trailing)
            }
            .font(.system(size: 9, weight: .bold, design: .default))
        }
    }
}

@available(iOS 16.1, *)
private struct DivergentBar: View {
    let left: Party
    let right: Party
    var height: CGFloat = 13

    // Head-to-head fill: each side takes a share of the full width proportional
    // to its seats within the pair, so the two colours meet at a boundary that
    // shows who leads. The golden tick marks the central dead-heat / majority line.
    private func fraction(_ party: Party) -> Double {
        let leftSeats = Double(Int(left.seatCount) ?? 0)
        let rightSeats = Double(Int(right.seatCount) ?? 0)
        let total = leftSeats + rightSeats
        guard total > 0 else { return 0.5 }
        return (Double(Int(party.seatCount) ?? 0)) / total
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Capsule()
                    .fill(.white.opacity(0.10))
                    .frame(height: height)
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color(electionHex: left.partyColour), Color(electionHex: left.partyColour1)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, w * fraction(left) - 1))
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color(electionHex: right.partyColour1), Color(electionHex: right.partyColour)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, w * fraction(right) - 1))
                }
                .frame(height: height)
                .clipShape(Capsule())
            }
            .frame(height: height)
        }
        .frame(height: height)
    }
}

// MARK: - Derived state

@available(iOS 16.1, *)
extension ElectionAttributes.ContentState {
    var rankedParties: [Party] {
        entries.sorted { (Int($0.seatCount) ?? 0) > (Int($1.seatCount) ?? 0) }
    }

    // The two compact bars below the headline: the next party pairs by rank.
    var miniPairs: [(Party, Party)] {
        let rest = Array(rankedParties.dropFirst(2))
        var pairs: [(Party, Party)] = []
        var index = 0
        while index + 1 < rest.count && pairs.count < 2 {
            pairs.append((rest[index], rest[index + 1]))
            index += 2
        }
        return pairs
    }
}

@available(iOS 16.1, *)
extension ActivityViewContext where Attributes == ElectionAttributes {
    var majorityReached: Bool {
        (state.rankedParties.first.flatMap { Int($0.seatCount) } ?? 0) >= state.halfwayCount
    }
    var majorityStatus: String {
        let ranked = state.rankedParties
        guard let leader = ranked.first, let leaderSeats = Int(leader.seatCount) else {
            return "הספירה בעיצומה"
        }
        if let challenger = ranked.dropFirst().first,
           let challengerSeats = Int(challenger.seatCount),
           challengerSeats == leaderSeats {
            return "תיקו בין \(leader.name) ל-\(challenger.name)"
        }
        if leaderSeats >= state.halfwayCount {
            return "\(leader.name) עבר את הרוב"
        }
        return "\(leader.name) מוביל · חסרים \(state.halfwayCount - leaderSeats) לרוב"
    }
}

private extension Party {
    var initials: String {
        let letters = name.filter { $0.isLetter }
        return String(letters.prefix(3)).uppercased()
    }
}

private extension Color {
    init(electionHex hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)
        let r, g, b: UInt64
        switch value.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: 1)
    }
}

// MARK: - Preview

@available(iOS 16.1, *)
extension ElectionAttributes {
    fileprivate static var preview: ElectionAttributes {
        ElectionAttributes(
            title: "בחירות לכנסת",
            electionName: "הכנסת ה-26 · 27 באוקטובר",
            pushwoosh: PushwooshLiveActivityAttributeData(activityId: "preview")
        )
    }
}

@available(iOS 16.1, *)
extension ElectionAttributes.ContentState {
    fileprivate static var counting: ElectionAttributes.ContentState {
        .init(halfwayCount: 61, targetCount: 120,
              entries: [
                Party(id: "likud", logo: "leader_netanyahu", name: "הליכוד", seatCount: "19", partyColour: "#1B4D9B", partyColour1: "#3A6FC4"),
                Party(id: "yashar", logo: "leader_eisenkot", name: "ישר", seatCount: "20", partyColour: "#12A594", partyColour1: "#3FC9B8"),
                Party(id: "together", logo: "together", name: "ביחד", seatCount: "13", partyColour: "#1E9BE0", partyColour1: "#58BEF0"),
                Party(id: "beiteinu", logo: "beiteinu", name: "ישראל ביתנו", seatCount: "7", partyColour: "#2C5C8A", partyColour1: "#4E82B4"),
                Party(id: "utj", logo: "utj", name: "יהדות התורה", seatCount: "7", partyColour: "#2E2E38", partyColour1: "#55555F"),
                Party(id: "shas", logo: "shas", name: "ש\"ס", seatCount: "6", partyColour: "#1C1C22", partyColour1: "#44444C"),
                Party(id: "otzma", logo: "otzma", name: "עוצמה יהודית", seatCount: "5", partyColour: "#C8781E", partyColour1: "#E0A040"),
                Party(id: "jointlist", logo: "jointlist", name: "הרשימה המשותפת", seatCount: "4", partyColour: "#C0392B", partyColour1: "#E05646"),
                Party(id: "democrats", logo: "democrats", name: "הדמוקרטים", seatCount: "4", partyColour: "#D6336C", partyColour1: "#E86C97"),
                Party(id: "rzp", logo: "rzp", name: "הציונות הדתית", seatCount: "3", partyColour: "#123C6B", partyColour1: "#2A5E96")
              ],
              pushwoosh: nil)
    }
    fileprivate static var result: ElectionAttributes.ContentState {
        .init(halfwayCount: 61, targetCount: 120,
              entries: [
                Party(id: "likud", logo: "leader_netanyahu", name: "הליכוד", seatCount: "22", partyColour: "#1B4D9B", partyColour1: "#3A6FC4"),
                Party(id: "yashar", logo: "leader_eisenkot", name: "ישר", seatCount: "22", partyColour: "#12A594", partyColour1: "#3FC9B8"),
                Party(id: "together", logo: "together", name: "ביחד", seatCount: "16", partyColour: "#1E9BE0", partyColour1: "#58BEF0"),
                Party(id: "beiteinu", logo: "beiteinu", name: "ישראל ביתנו", seatCount: "9", partyColour: "#2C5C8A", partyColour1: "#4E82B4"),
                Party(id: "utj", logo: "utj", name: "יהדות התורה", seatCount: "8", partyColour: "#2E2E38", partyColour1: "#55555F"),
                Party(id: "shas", logo: "shas", name: "ש\"ס", seatCount: "7", partyColour: "#1C1C22", partyColour1: "#44444C"),
                Party(id: "otzma", logo: "otzma", name: "עוצמה יהודית", seatCount: "7", partyColour: "#C8781E", partyColour1: "#E0A040"),
                Party(id: "jointlist", logo: "jointlist", name: "הרשימה המשותפת", seatCount: "5", partyColour: "#C0392B", partyColour1: "#E05646"),
                Party(id: "democrats", logo: "democrats", name: "הדמוקרטים", seatCount: "5", partyColour: "#D6336C", partyColour1: "#E86C97"),
                Party(id: "rzp", logo: "rzp", name: "הציונות הדתית", seatCount: "4", partyColour: "#123C6B", partyColour1: "#2A5E96")
              ],
              pushwoosh: nil)
    }
}

@available(iOS 16.2, *)
#Preview("Election", as: .content, using: ElectionAttributes.preview) {
    ElectionActivity()
} contentStates: {
    ElectionAttributes.ContentState.counting
    ElectionAttributes.ContentState.result
}
