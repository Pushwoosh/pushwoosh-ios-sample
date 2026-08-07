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
    @State private var activeAppCode = Pushwoosh.configure.getAppCode() ?? "—"
    @State private var activeBaseUrl = Pushwoosh.configure.getBaseUrl() ?? "—"
    @ObservedObject private var traffic = MockTrafficLog.shared

    // The region pairs a customer ships live in StoreRegion (Switch account). This screen only adds
    // the host a region can be moved to, so an endpoint-only switch can be exercised.
    private let movedUrl = "http://127.0.0.1:9597/json/1.3/"

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    logLevelCard
                    switchVariantsCard
                    activePairCard
                    serverTrafficCard
                    mockServerControlsCard
                    actionsCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .onAppear {
            LocalPushwooshServer.shared.startIfNeeded()
            LocalPushwooshServer.secondRegion.startIfNeeded()
            LocalPushwooshServer.secondRegionMoved.startIfNeeded()
        }
    }

    private var switchVariantsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Switch variants").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                Text("Each button changes exactly one thing relative to the pair shown below, so the three shapes of a switch can be told apart.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)

                PushMartButton(title: "Application only (Honduras application, US endpoint)", icon: "arrow.left.arrow.right.circle", style: .secondary) {
                    switchTo(StoreRegion.honduras.appCode, StoreRegion.unitedStates.baseUrl, "Application only")
                }
                PushMartButton(title: "Endpoint only (same application, moved host)", icon: "arrow.uturn.right.circle", style: .secondary) {
                    let code = Pushwoosh.configure.getAppCode() ?? StoreRegion.honduras.appCode
                    switchTo(code, movedUrl, "Endpoint only")
                }
                PushMartButton(title: "Repeat the selected pair (free, or undoes a rotation)", icon: "equal.circle", style: .secondary) {
                    // Repeats the pair this app chose, deliberately not getBaseUrl(): that returns the
                    // endpoint currently in effect, which the server may have rotated, and passing it
                    // back would record the rotation as the app's own choice. With the app's own pair
                    // this call is free when nothing moved and puts the endpoint back after a rotation.
                    let region = StoreRegion.stored ?? .honduras
                    switchTo(region.appCode, region.baseUrl, "Repeat")
                }
                PushMartButton(title: "No endpoint supplied (same as the one-argument setter)", icon: "arrow.uturn.backward", style: .secondary) {
                    let code = Pushwoosh.configure.getAppCode() ?? StoreRegion.unitedStates.appCode
                    switchTo(code, nil, "Nil endpoint")
                }
                PushMartButton(title: "Invalid endpoint (must be rejected)", icon: "exclamationmark.triangle", style: .secondary) {
                    let code = Pushwoosh.configure.getAppCode() ?? StoreRegion.unitedStates.appCode
                    switchTo(code, "ftp://not-an-endpoint", "Invalid endpoint")
                }
            }
        }
    }

    @State private var rotateArmed = false
    @State private var hondurasRunning = true

    // Failure-mode switches for the mock backend, so the SDK's guards can be watched working:
    // a rotation coming back on the previous application's unregister must be ignored, and an
    // unregister aimed at a dead region must land in the persistent queue instead of vanishing.
    private var mockServerControlsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Mock server controls").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)

                PushMartButton(title: rotateArmed ? "Armed: next unregister replies with a rotated base_url" : "Rotate base_url on next unregister",
                               icon: rotateArmed ? "checkmark.circle" : "arrow.triangle.2.circlepath.circle",
                               style: .secondary) {
                    LocalPushwooshServer.rotateBaseUrlOnNextUnregister.toggle()
                    rotateArmed = LocalPushwooshServer.rotateBaseUrlOnNextUnregister
                }

                PushMartButton(title: hondurasRunning ? "Stop the Honduras server (9596)" : "Start the Honduras server (9596)",
                               icon: hondurasRunning ? "stop.circle" : "play.circle",
                               style: .secondary) {
                    if hondurasRunning {
                        LocalPushwooshServer.secondRegion.stop()
                    } else {
                        LocalPushwooshServer.secondRegion.startIfNeeded()
                    }
                    hondurasRunning = LocalPushwooshServer.secondRegion.isRunning
                }
            }
        }
        .onAppear {
            rotateArmed = LocalPushwooshServer.rotateBaseUrlOnNextUnregister
            hondurasRunning = LocalPushwooshServer.secondRegion.isRunning
        }
    }

    private var activePairCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Selected pair").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)

                HStack {
                    Text("Application code").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                    Spacer()
                    Text(activeAppCode)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(PushMart.textPrimary)
                }
                HStack(alignment: .top) {
                    Text("Base URL").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
                    Spacer()
                    Text(activeBaseUrl)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(PushMart.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
                .sdkNote("Pushwoosh.configure.getAppCode() / getBaseUrl()",
                         "Reads the application code and API endpoint the SDK currently uses.",
                         calls: [
                            .init(code: "Pushwoosh.configure.getAppCode()",
                                  note: "Read - the active application code."),
                            .init(code: "Pushwoosh.configure.getBaseUrl()",
                                  note: "Read - the resolved API base URL. Reflects a server-side rotation, so it is not always the URL that was passed in."),
                         ])
            }
        }
        .onAppear { refreshActiveApplication() }
    }

    // Traffic the local mock servers answered, newest first. The port tells the region apart and
    // `application` is what the request body actually carried - that pair is the point of a switch.
    private var serverTrafficCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Server traffic").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    Button("Clear") { traffic.clear() }
                        .font(PushMart.body(13))
                        .foregroundStyle(PushMart.textSecondary)
                }
                Text("Requests the local region mocks answered: 9595 United States, 9596 Honduras, 9597 the moved host.")
                    .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if traffic.entries.isEmpty {
                    Text("No requests yet")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(PushMart.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(traffic.entries.prefix(25)) { entry in
                            HStack(spacing: 8) {
                                Text(entry.time)
                                    .foregroundStyle(PushMart.textSecondary)
                                Text("\(entry.port)")
                                    .foregroundStyle(PushMart.textPrimary)
                                Text(entry.method)
                                    .foregroundStyle(PushMart.textPrimary)
                                Spacer()
                                Text(entry.application)
                                    .foregroundStyle(PushMart.textSecondary)
                            }
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                    }
                }
            }
        }
    }

    // One entry point for every variant, so the console shows the same shape of line whatever
    // changed: the pair asked for, then the pair the SDK ended up with.
    private func switchTo(_ appCode: String, _ baseUrl: String?, _ label: String) {
        NSLog("%@", "PW_REGION request=\(label) appCode=\(appCode) baseUrl=\(baseUrl ?? "nil")")
        Pushwoosh.configure.setAppCode(appCode, baseUrl: baseUrl)
        refreshActiveApplication()
        NSLog("%@", "PW_REGION applied=\(label) appCode=\(activeAppCode) baseUrl=\(activeBaseUrl)")
        PushMartResult.shared.success("\(label): \(activeAppCode)")
    }

    private func refreshActiveApplication() {
        activeAppCode = Pushwoosh.configure.getAppCode() ?? "—"
        activeBaseUrl = Pushwoosh.configure.getBaseUrl() ?? "—"
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
