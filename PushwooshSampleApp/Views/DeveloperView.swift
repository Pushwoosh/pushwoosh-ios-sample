//
//  DeveloperView.swift
//  PushMart
//
//  Created by André Kis
//
//  DEBUG-only diagnostics. Wrapped entirely in #if DEBUG so it never ships in a
//  release build (no "demo tool" surface in the App Store binary), while still
//  showing how the diagnostic SDK methods are used.
//

#if DEBUG
import SwiftUI
import PushwooshFramework

struct DeveloperView: View {
    private let levels: [(name: String, level: PUSHWOOSH_LOG_LEVEL)] = [
        ("None", .PW_LL_NONE), ("Error", .PW_LL_ERROR), ("Warn", .PW_LL_WARN),
        ("Info", .PW_LL_INFO), ("Debug", .PW_LL_DEBUG), ("Verbose", .PW_LL_VERBOSE)
    ]
    @State private var selected = "Debug"

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    logLevelCard
                    actionsCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Developer").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("Diagnostics · debug builds only").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(.top, 4)
    }

    private var logLevelCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("SDK log level").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                FlowChips(items: levels.map { $0.name }, selected: [selected]) { name in
                    guard let entry = levels.first(where: { $0.name == name }) else { return }
                    selected = name
                    Pushwoosh.debug.setLogLevel(entry.level)
                    PushMartResult.shared.success("Log level: \(name)")
                }
                .sdkNote("Pushwoosh.debug.setLogLevel(_:)",
                         "Sets how much detail the SDK writes to the Xcode console.",
                         calls: [
                            .init(code: "setLogLevel(.PW_LL_NONE)",
                                  note: "None - silence all SDK logging."),
                            .init(code: "setLogLevel(.PW_LL_ERROR)",
                                  note: "Error - log only errors."),
                            .init(code: "setLogLevel(.PW_LL_WARN)",
                                  note: "Warn - log warnings and errors."),
                            .init(code: "setLogLevel(.PW_LL_INFO)",
                                  note: "Info - log high-level info plus warnings and errors."),
                            .init(code: "setLogLevel(.PW_LL_DEBUG)",
                                  note: "Debug - log detailed debug output (the sample's default)."),
                            .init(code: "setLogLevel(.PW_LL_VERBOSE)",
                                  note: "Verbose - log everything the SDK emits."),
                         ])
                Text("Controls how much the SDK logs to the console.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
            }
        }
    }

    private var actionsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Diagnostics").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)

                PushMartButton(title: "Reload in-app resources", icon: "arrow.clockwise", style: .secondary) {
                    PWInAppManager.shared().reloadInApps { error in
                        DispatchQueue.main.async {
                            if let error {
                                PushMartResult.shared.fail("Reload failed", error.localizedDescription)
                            } else {
                                PushMartResult.shared.success("In-app resources reloaded")
                            }
                        }
                    }
                }
                .sdkNote("PWInAppManager.shared().reloadInApps { }",
                         "Re-downloads the in-app message resources from Pushwoosh.",
                         calls: [
                            .init(code: "PWInAppManager.shared().reloadInApps { error in }",
                                  note: "Reload - fetches the latest in-app messages, then reports success or the error in the completion."),
                         ])

                HStack {
                    Text("SDK version").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                    Spacer()
                    Text(Pushwoosh.configure.version())
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(PushMart.textPrimary)
                }
                .sdkNote("Pushwoosh.configure.version()",
                         "Returns the Pushwoosh SDK version string.",
                         calls: [
                            .init(code: "Pushwoosh.configure.version()",
                                  note: "Read - shown in the row to display the SDK version bundled in the app."),
                         ])
            }
        }
    }
}
#endif
