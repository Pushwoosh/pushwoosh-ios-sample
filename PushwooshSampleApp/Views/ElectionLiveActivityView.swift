//
//  ElectionLiveActivityView.swift
//  PushMart
//
//  "Election night": a fully local Live Activity demo (no Pushwoosh push). The
//  screen starts an Activity<ElectionAttributes> with Activity.request(pushType: nil),
//  then each "Update" press pushes the next round of results with activity.update —
//  exactly the shape an updateLiveActivity campaign would send from the backend, but
//  driven locally so the card can be exercised without a server. Stop ends the card.
//

import SwiftUI
import ActivityKit
import PushwooshFramework
import PushwooshLiveActivities

// MARK: - Controller

@MainActor
final class ElectionLiveActivityController: ObservableObject {
    @Published var isRunning = false
    @Published var round = 0
    @Published var status = "Start the tracker to pin a live Knesset results card"
    @Published var entries: [Party] = ElectionLiveActivityController.rounds[0]

    private var activityBox: Any?

    let title = "בחירות לכנסת"
    let electionName = "הכנסת ה-26 · 27 באוקטובר"
    let halfwayCount = 61
    let targetCount = 120
    let activityId = "knesset-2026"

    // Growing seat tallies per counting round (Lazar/Maariv poll, 17 Jul 2026).
    // Party fields (id/logo/name/seatCount/partyColour/partyColour1) match the
    // client's updateLiveActivity payload 1:1. Likud & Yashar carry a leader-photo
    // asset name in `logo`; the rest fall back to initials on the Lock Screen.
    static let rounds: [[Party]] = [
        [
            Party(id: "likud", logo: "leader_netanyahu", name: "הליכוד", seatCount: "8", partyColour: "#1B4D9B", partyColour1: "#3A6FC4"),
            Party(id: "yashar", logo: "leader_eisenkot", name: "ישר", seatCount: "6", partyColour: "#12A594", partyColour1: "#3FC9B8"),
            Party(id: "together", logo: "together", name: "ביחד", seatCount: "5", partyColour: "#1E9BE0", partyColour1: "#58BEF0"),
            Party(id: "beiteinu", logo: "beiteinu", name: "ישראל ביתנו", seatCount: "3", partyColour: "#2C5C8A", partyColour1: "#4E82B4"),
            Party(id: "utj", logo: "utj", name: "יהדות התורה", seatCount: "3", partyColour: "#2E2E38", partyColour1: "#55555F"),
            Party(id: "shas", logo: "shas", name: "ש\"ס", seatCount: "2", partyColour: "#1C1C22", partyColour1: "#44444C"),
            Party(id: "otzma", logo: "otzma", name: "עוצמה יהודית", seatCount: "2", partyColour: "#C8781E", partyColour1: "#E0A040"),
            Party(id: "jointlist", logo: "jointlist", name: "הרשימה המשותפת", seatCount: "2", partyColour: "#C0392B", partyColour1: "#E05646"),
            Party(id: "democrats", logo: "democrats", name: "הדמוקרטים", seatCount: "1", partyColour: "#D6336C", partyColour1: "#E86C97"),
            Party(id: "rzp", logo: "rzp", name: "הציונות הדתית", seatCount: "1", partyColour: "#123C6B", partyColour1: "#2A5E96")
        ],
        [
            Party(id: "likud", logo: "leader_netanyahu", name: "הליכוד", seatCount: "14", partyColour: "#1B4D9B", partyColour1: "#3A6FC4"),
            Party(id: "yashar", logo: "leader_eisenkot", name: "ישר", seatCount: "13", partyColour: "#12A594", partyColour1: "#3FC9B8"),
            Party(id: "together", logo: "together", name: "ביחד", seatCount: "9", partyColour: "#1E9BE0", partyColour1: "#58BEF0"),
            Party(id: "beiteinu", logo: "beiteinu", name: "ישראל ביתנו", seatCount: "5", partyColour: "#2C5C8A", partyColour1: "#4E82B4"),
            Party(id: "utj", logo: "utj", name: "יהדות התורה", seatCount: "5", partyColour: "#2E2E38", partyColour1: "#55555F"),
            Party(id: "shas", logo: "shas", name: "ש\"ס", seatCount: "4", partyColour: "#1C1C22", partyColour1: "#44444C"),
            Party(id: "otzma", logo: "otzma", name: "עוצמה יהודית", seatCount: "3", partyColour: "#C8781E", partyColour1: "#E0A040"),
            Party(id: "jointlist", logo: "jointlist", name: "הרשימה המשותפת", seatCount: "3", partyColour: "#C0392B", partyColour1: "#E05646"),
            Party(id: "democrats", logo: "democrats", name: "הדמוקרטים", seatCount: "3", partyColour: "#D6336C", partyColour1: "#E86C97"),
            Party(id: "rzp", logo: "rzp", name: "הציונות הדתית", seatCount: "2", partyColour: "#123C6B", partyColour1: "#2A5E96")
        ],
        [
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
        [
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
        ]
    ]

    private var isFinalRound: Bool { round >= ElectionLiveActivityController.rounds.count - 1 }

    func configure() {
        if #available(iOS 16.1, *) {
            Pushwoosh.LiveActivities.setup(ElectionAttributes.self)
        }
    }

    private func state(for round: Int) -> ElectionAttributes.ContentState {
        ElectionAttributes.ContentState(
            halfwayCount: halfwayCount,
            targetCount: targetCount,
            entries: ElectionLiveActivityController.rounds[round],
            pushwoosh: nil
        )
    }

    func start() {
        guard #available(iOS 16.1, *) else { status = "Needs iOS 16.1"; return }
        guard activityBox == nil else { status = "Already tracking — Stop first"; return }

        round = 0
        entries = ElectionLiveActivityController.rounds[0]

        let attributes = ElectionAttributes(
            title: title,
            electionName: electionName,
            pushwoosh: PushwooshLiveActivityAttributeData(activityId: activityId)
        )

        do {
            let activity = try Activity<ElectionAttributes>.request(
                attributes: attributes,
                contentState: state(for: 0),
                pushType: nil
            )
            activityBox = activity
            isRunning = true
            status = "Live · polls closed, first trends in"
        } catch {
            status = "Request error: \(error.localizedDescription)"
        }
    }

    func update() {
        guard #available(iOS 16.1, *) else { return }
        guard let activity = activityBox as? Activity<ElectionAttributes> else {
            status = "Start the tracker first"; return
        }
        guard !isFinalRound else {
            status = "Counting complete — final tally declared"; return
        }

        round += 1
        entries = ElectionLiveActivityController.rounds[round]
        let content = state(for: round)

        Task {
            if #available(iOS 16.2, *) {
                await activity.update(ActivityContent(state: content, staleDate: nil))
            } else {
                await activity.update(using: content)
            }
        }

        let leader = ranked(entries).first
        if let leader, let seats = Int(leader.seatCount), seats >= halfwayCount {
            status = "\(leader.name) crosses majority · results declared"
        } else {
            status = isFinalRound ? "Final tally declared" : "Round \(round + 1) — counting continues"
        }
    }

    func stop() {
        guard #available(iOS 16.1, *) else { return }
        if let activity = activityBox as? Activity<ElectionAttributes> {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        activityBox = nil
        isRunning = false
        round = 0
        entries = ElectionLiveActivityController.rounds[0]
        status = "Stopped — results card removed"
    }

    func ranked(_ parties: [Party]) -> [Party] {
        parties.sorted { (Int($0.seatCount) ?? 0) > (Int($1.seatCount) ?? 0) }
    }
}

// MARK: - Screen

struct ElectionLiveActivityView: View {
    @StateObject private var controller = ElectionLiveActivityController()

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    statusPill
                    standingsCard
                    controlsCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .onAppear { controller.configure() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(PushMart.warning.opacity(0.16)).frame(width: 50, height: 50)
                Image(systemName: "chart.bar.fill").font(.system(size: 20, weight: .bold)).foregroundColor(PushMart.warning)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("ELECTION NIGHT")
                    .font(PushMart.label(13)).tracking(2).foregroundColor(PushMart.warning)
                Text("Live seat tracker on your Lock Screen")
                    .font(PushMart.body(14)).foregroundColor(PushMart.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 16)
    }

    private var statusPill: some View {
        Text(controller.status)
            .font(PushMart.body(13)).foregroundColor(PushMart.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12).padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(PushMart.surface))
    }

    private var standingsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(controller.title)
                        .font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    Text("\(controller.targetCount) seats · maj \(controller.halfwayCount)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(PushMart.textTertiary)
                }

                ForEach(controller.ranked(controller.entries), id: \.id) { party in
                    partyRow(party)
                }
            }
        }
    }

    private func partyRow(_ party: Party) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(electionHex: party.partyColour), Color(electionHex: party.partyColour1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(partyInitials(party))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(party.name).font(PushMart.headline(15)).foregroundColor(PushMart.textPrimary)
                    Spacer()
                    Text(party.seatCount).font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(PushMart.textPrimary)
                }
                seatBar(party)
            }
        }
    }

    private func seatBar(_ party: Party) -> some View {
        GeometryReader { geo in
            let fraction = min(1.0, Double(Int(party.seatCount) ?? 0) / Double(max(1, controller.targetCount)))
            let majority = min(1.0, Double(controller.halfwayCount) / Double(max(1, controller.targetCount)))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10)).frame(height: 7)
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(electionHex: party.partyColour), Color(electionHex: party.partyColour1)],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(7, geo.size.width * fraction), height: 7)
                Rectangle().fill(PushMart.warning).frame(width: 1.5, height: 12)
                    .offset(x: geo.size.width * majority)
            }
            .frame(height: 12)
        }
        .frame(height: 12)
    }

    private var controlsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                PushMartButton(
                    title: controller.isRunning ? "Tracking live" : "Start live tracker",
                    icon: controller.isRunning ? "dot.radiowaves.left.and.right" : "play.fill",
                    style: controller.isRunning ? .secondary : .primary
                ) {
                    controller.start()
                }
                .sdkNote(
                    "Activity<ElectionAttributes>.request(attributes:contentState:pushType: nil)",
                    "Starts the election results Live Activity locally, with no Pushwoosh push involved.",
                    docs: "Pushwoosh.LiveActivities.setup(ElectionAttributes.self) is called once on appear so the SDK can track this activity type. Passing pushType: nil starts a purely local activity: iOS issues no push token and the card is only ever updated by the app itself via activity.update.",
                    calls: [
                        .init(code: "try Activity<ElectionAttributes>.request(attributes: attrs, contentState: initial, pushType: nil)",
                              note: "Pins the results card with the first counting round. pushType: nil keeps it fully local.")
                    ])

                PushMartButton(
                    title: "Update results",
                    icon: "arrow.up.forward",
                    style: .primary
                ) {
                    controller.update()
                }
                .sdkNote(
                    "activity.update(ActivityContent(state:staleDate:))",
                    "Pushes the next counting round into the live card — the same content shape a backend updateLiveActivity campaign would send.",
                    docs: "Each press advances to the next round of seat tallies and calls activity.update with a fresh ElectionAttributes.ContentState (halfwayCount, targetCount, entries). This is the local equivalent of a remote Live Activity update.",
                    calls: [
                        .init(code: "await activity.update(ActivityContent(state: content, staleDate: nil))",
                              note: "Replaces the card's ContentState with the next round's seat counts.")
                    ])

                PushMartButton(title: "Stop tracker", icon: "stop.fill", style: .secondary) {
                    controller.stop()
                }
                .sdkNote(
                    "activity.end(nil, dismissalPolicy: .immediate)",
                    "Ends the local Live Activity and removes the results card.",
                    calls: [
                        .init(code: "await activity.end(nil, dismissalPolicy: .immediate)",
                              note: "Dismisses the election card from the Lock Screen and Dynamic Island right away.")
                    ])
            }
        }
    }

    private func partyInitials(_ party: Party) -> String {
        String(party.name.filter { $0.isLetter }.prefix(3)).uppercased()
    }
}

fileprivate extension Color {
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
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

#Preview {
    ElectionLiveActivityView()
}
