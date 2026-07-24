//
//  PushwooshSampleApp.swift
//  PushMart
//
//  Created by André Kis
//

import SwiftUI
import Network
import PushwooshFramework
import PushwooshLiveActivities
import StoreKit

// Routes SDK traffic either to the built-in local server (LocalPushwooshServer) or to the
// production endpoint. Toggle lives on the Media screen and applies immediately.
enum ServerRouting {
    static func apply() {
        let useMockServer = UserDefaults.standard.bool(forKey: "PWMockServerEnabled")
        if useMockServer {
            LocalPushwooshServer.shared.startIfNeeded()
            Pushwoosh.configure.setReverseProxy("http://127.0.0.1:9595/json/1.3/", headers: nil)
        } else {
            let appCode = PushMartStore.appCode
            // No valid app code yet (first run, before onboarding) — don't point the proxy at a
            // broken "https://.api.pushwoosh.com" host. ServerRouting.apply() runs again once a
            // code is entered in onboarding / settings.
            guard appCode.isValidAppCode else { return }
            Pushwoosh.configure.setReverseProxy("https://\(appCode).api.pushwoosh.com/json/1.3/", headers: nil)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, PWMessagingDelegate, PWRichMediaPresentingDelegate, PWPurchaseDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Skip Pushwoosh initialization during UI tests
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
            print("🧪 UI Testing mode - skipping Pushwoosh initialization")
            return true
        }

        configureServerRouting()

        Pushwoosh.configure.delegate = self

        // Purchase tracking: rich-media-driven IAP callbacks come through the purchase delegate,
        // and any StoreKit transactions the app completes itself are forwarded to Pushwoosh so
        // purchases land as events without a manual sendPurchase call.
        Pushwoosh.configure.purchaseDelegate = self
        PurchaseTracker.shared.start()

        applyE2ENotificationHooksIfRequested()

        // Register EVERY Live Activity attributes type the app uses here, at launch. setup() is what
        // lets the SDK re-attach to already-running activities of that type and re-upload their push
        // token after a cold start (e.g. an activity that started while the app was killed). A type
        // registered lazily (only when its screen appears) won't be reconnected until that screen is
        // opened — so remote updates to it silently go nowhere until then. The per-screen setup() calls
        // in the demo views are idempotent and stay as-is; these are the ones that matter for reconnect.
        if #available(iOS 16.1, *) {
            Pushwoosh.LiveActivities.setup(LiveActivityDemoAttributes.self)
            Pushwoosh.LiveActivities.setup(LiveScoreAttributes.self)
            Pushwoosh.LiveActivities.setup(RadioBroadcastAttributes.self)
            Pushwoosh.LiveActivities.setup(ElectionAttributes.self)
            Pushwoosh.LiveActivities.defaultSetup()
        }

        Pushwoosh.media.setRichMediaPresentationStyle(.modal)

        Pushwoosh.media.modalRichMedia.configure(with: .PWModalWindowPositionBottom,
                                                 present: .PWAnimationPresentDropDown,
                                                 dismiss: .PWAnimationDismissSlideRight)

        Pushwoosh.media.modalRichMedia.setHapticFeedbackType(.PWHapticFeedbackLight)

        // Receive rich-media lifecycle callbacks (present / close / fail). shouldPresent below still
        // gates actual presentation, so E2E suppression via PW_SUPPRESS_RICH_MEDIA is unaffected.
        PWRichMediaManager.shared().delegate = self
        Pushwoosh.media.modalRichMedia.setDelegate(self)
        _ = Pushwoosh.media.modalRichMedia.getDelegate()

        // In-app foreground push banner: brand it, set display timing, and route taps.
        Pushwoosh.ForegroundPush.backgroundColor = UIColor(red: 0.11, green: 0.13, blue: 0.20, alpha: 1.0)
        Pushwoosh.ForegroundPush.titlePushColor = .white
        Pushwoosh.ForegroundPush.messagePushColor = UIColor(white: 1.0, alpha: 0.75)
        Pushwoosh.ForegroundPush.usePushAnimation = true
        Pushwoosh.ForegroundPush.useLiquidView = true
        Pushwoosh.ForegroundPush.foregroundNotificationWith(style: .style1,
                                                            duration: 4,
                                                            vibration: .light,
                                                            disappearedPushAnimation: .regularPush)
        Pushwoosh.ForegroundPush.didTapForegroundPush = { userInfo in
            print("Foreground push tapped: \(userInfo)")
            DeepLinkRouter.shared.route(userInfo)
        }

        // Expose a native object to rich-media HTML: JS can call window.PushMart.execute()/… .
        PWInAppManager.shared().addJavascriptInterface(PushMartJSBridge.shared, withName: "PushMart")

        // VoIP: set the call delegate and configure incoming-call presentation. The SDK owns the
        // PKPushRegistry and token/incoming-push handling; the app only sets the delegate here.
        VoIPController.shared.start()

        // If the app was cold-launched by tapping a push, route its custom data.
        if let launch = Pushwoosh.configure.launchNotification() {
            DispatchQueue.main.async { DeepLinkRouter.shared.route(launch) }
        }

        return true
    }

    private func configureServerRouting() {
        ServerRouting.apply()
    }

    // Push Primer: soft opt-in dialog shown before the system push prompt. State-aware — it
    // auto-suppresses when notifications are already authorized. Presented on demand from the
    // Reminders screen's "Enable notifications" button, not automatically at launch.
    static func showPushPrimer() {
        let primer = Pushwoosh.configure.pushPrimer
            .style(.sheet)
            .position(.center)
            .title("Stay in the loop")
            .message("Enable notifications to get deals and order updates first")
            .acceptButton("Enable notifications")
            .declineButton("Not now")
            // Pushwoosh brand colors: dark navy + signature green (all optional)
            .backgroundColor(UIColor(red: 0.11, green: 0.13, blue: 0.20, alpha: 1.0))
            .backgroundGradient([
                UIColor(red: 0.11, green: 0.13, blue: 0.20, alpha: 1.0),   // navy
                UIColor(red: 0.13, green: 0.26, blue: 0.27, alpha: 1.0),   // deep teal
                UIColor(red: 0.11, green: 0.13, blue: 0.20, alpha: 1.0)    // navy
            ])
            .titleColor(.white)
            .messageColor(UIColor(white: 1.0, alpha: 0.72))
            .acceptButtonColor(UIColor(red: 0.18, green: 0.89, blue: 0.61, alpha: 1.0))   // Pushwoosh green
            .acceptButtonTextColor(UIColor(red: 0.11, green: 0.13, blue: 0.20, alpha: 1.0))
            .declineButtonColor(UIColor(white: 1.0, alpha: 0.10))
            .declineButtonTextColor(UIColor(white: 1.0, alpha: 0.85))
            .cornerRadius(24)
            .buttonCornerRadius(14)
            .buttonBorderColor(UIColor(red: 0.18, green: 0.89, blue: 0.61, alpha: 0.35))
            // If notifications were previously denied, the accept button deep-links to Settings.
            .fallbackToSettings(true)
            // Throttle: 0 = show on every eligible launch (default). Set e.g. 7*24*60*60 for weekly.
            .minInterval(0)

        if let hero = UIImage(named: "PushPrimerHero") {
            _ = primer.image(hero)
        }

        primer.present { outcome in
            print("Push primer outcome: \(outcome.rawValue)")
        }
    }

    func richMediaManager(_ richMediaManager: PWRichMediaManager, shouldPresent richMedia: PWRichMedia) -> Bool {
        return ProcessInfo.processInfo.environment["PW_SUPPRESS_RICH_MEDIA"] != "1"
    }

    func richMediaManager(_ richMediaManager: PWRichMediaManager, didPresent richMedia: PWRichMedia) {
        print("Rich media presented: source \(richMedia.source.rawValue)")
    }

    func richMediaManager(_ richMediaManager: PWRichMediaManager, didClose richMedia: PWRichMedia) {
        print("Rich media closed: source \(richMedia.source.rawValue)")
    }

    func richMediaManager(_ richMediaManager: PWRichMediaManager, presentingDidFailFor richMedia: PWRichMedia, withError error: any Error) {
        print("Rich media presenting failed: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Pushwoosh.configure.handlePushRegistration(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        Pushwoosh.configure.handlePushRegistrationFailure(error as NSError)
        print("\(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Pushwoosh.configure.handlePushReceived(userInfo)

        completionHandler(.noData)
    }

    func pushwoosh(_ pushwoosh: Pushwoosh, onMessageOpened message: PWMessage) {
        print("Push Opened: \(message.payload ?? ["" : ""])")
        // Extract the raw custom-data JSON straight from the APNs payload.
        if let payload = message.payload,
           let customJSON = Pushwoosh.configure.getCustomPushData(payload) {
            print("Custom push data: \(customJSON)")
        }
        // Route campaign custom data (product_id / voucher / sale) into the app.
        DeepLinkRouter.shared.route(message.customData)
    }

    func pushwoosh(_ pushwoosh: Pushwoosh, onMessageReceived message: PWMessage) {
        // print("Push Received: \(message.payload ?? ["" : ""])")
    }

    // MARK: - PWPurchaseDelegate (in-app purchases triggered from rich media)

    func onPW(inAppPurchaseHelperProducts products: [SKProduct]?) {
        print("IAP products loaded: \(products?.map { $0.productIdentifier } ?? [])")
    }

    func onPW(inAppPurchaseHelperPaymentComplete identifier: String?) {
        print("IAP payment complete: \(identifier ?? "—")")
        PushMartResult.shared.success("Purchase complete", identifier ?? "")
    }

    func onPW(inAppPurchaseHelperPaymentFailedProductIdentifier identifier: String?, error: Error?) {
        print("IAP payment failed: \(identifier ?? "—") · \(error?.localizedDescription ?? "")")
        PushMartResult.shared.fail("Purchase failed", error?.localizedDescription ?? (identifier ?? ""))
    }

    func onPW(inAppPurchaseHelperCallPromotedPurchase identifier: String?) {
        print("IAP promoted purchase: \(identifier ?? "—")")
    }

    func onPW(inAppPurchaseHelperRestoreCompletedTransactionsFailed error: Error?) {
        print("IAP restore failed: \(error?.localizedDescription ?? "")")
    }

    // MARK: - SDK-849 E2E hooks (launch-env gated; a complete no-op in normal runs)

    private static var e2eFakeProviders: [PWE2EFakeProvider] = []
    private static var e2eManualDelegate: PWE2EManualForwardingDelegate?

    /// Wires up the env-driven test surface for SDK-849. Does nothing unless a `PW_E2E_*`
    /// launch environment variable is present, so normal launches and other E2E suites are
    /// unaffected.
    private func applyE2ENotificationHooksIfRequested() {
        let env = ProcessInfo.processInfo.environment

        // Imitate third-party push SDKs (Firebase / OneSignal) as additional
        // UNUserNotificationCenterDelegates registered through Pushwoosh's proxy.
        //   PW_E2E_FAKE_PROVIDERS = how many fakes to register
        //   PW_E2E_FAKE_SILENT    = "1" -> fakes do NOT call the completion handler
        //                           (exercises the proxy's exactly-once fallback)
        if let count = env["PW_E2E_FAKE_PROVIDERS"].flatMap(Int.init), count > 0 {
            _ = Pushwoosh.sharedInstance()   // ensure init ran (proxy + bridge block exist); `Pushwoosh.configure` above already triggers it — defensive, so this hook does not depend on call order
            let silent = env["PW_E2E_FAKE_SILENT"] == "1"
            for i in 1...count {
                let fake = PWE2EFakeProvider(tag: "\(i)", callsHandler: !silent)
                AppDelegate.e2eFakeProviders.append(fake)
                Pushwoosh.configure.addNotificationCenterDelegate(fake)
            }
            NSLog("%@", "PW_E2E_HOOK registered=\(count) silent=\(silent)")
        }

        // Opt-out manual path: when Pushwoosh releases the delegate seat
        // (Pushwoosh_PLUGIN_NOTIFICATION_HANDLER=YES), the host owns the seat and manually forwards
        // each callback to Pushwoosh.configure.handleWillPresentNotification(_:completionHandler:).
        // Proves the manual forward-API actually works under opt-out — the real contract of the flag.
        // Runs BEFORE the delegate-seat report below so REPORT_DELEGATE observes the installed delegate.
        if env["PW_E2E_MANUAL_FORWARD"] == "1" {
            _ = Pushwoosh.sharedInstance()
            let own = PWE2EManualForwardingDelegate()
            AppDelegate.e2eManualDelegate = own
            UNUserNotificationCenter.current().delegate = own
            NSLog("%@", "PW_E2E_MANUAL installed own delegate")
        }

        // Report who currently owns the UNUserNotificationCenter delegate seat — lets the
        // opt-out scenario assert the Pushwoosh proxy did NOT take it over.
        if env["PW_E2E_REPORT_DELEGATE"] == "1" {
            let owner = UNUserNotificationCenter.current().delegate
            NSLog("%@", "PW_E2E_DELEGATE_CLASS=\(owner.map { String(describing: type(of: $0)) } ?? "nil")")
        }
    }

}

/// E2E-only stand-in for a third-party push SDK (Firebase / OneSignal): just another
/// `UNUserNotificationCenterDelegate`. It prints a unique marker and optionally calls its
/// completion handler, exactly like a real third-party SDK would — so the proxy's
/// exactly-once guard and its forwarding can be exercised end-to-end on a real push.
// Forwards StoreKit transactions the app completes to Pushwoosh so purchases are auto-tracked
// as events via Pushwoosh.configure.sendSKPaymentTransactions. Registered once at launch.
final class PurchaseTracker: NSObject, SKPaymentTransactionObserver {
    static let shared = PurchaseTracker()
    private var started = false

    func start() {
        guard !started, !PushwooshHelper.isUITesting else { return }
        started = true
        SKPaymentQueue.default().add(self)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        let finished = transactions.filter { $0.transactionState == .purchased || $0.transactionState == .restored }
        guard !finished.isEmpty else { return }
        Pushwoosh.configure.sendSKPaymentTransactions(finished)
    }
}

// Native bridge exposed to rich-media HTML via PWInAppManager.addJavascriptInterface.
// JS calls `window.PushMart.execute()` / `executeWithParam(...)`; the returned string is
// handed back to the web view. All PWJavaScriptInterface methods are optional.
final class PushMartJSBridge: NSObject, PWJavaScriptInterface {
    static let shared = PushMartJSBridge()

    func execute() -> String {
        return "{\"app\":\"PushMart\"}"
    }

    func execute(withParam param: String) -> String {
        return "{\"echo\":\"\(param)\"}"
    }
}

final class PWE2EFakeProvider: NSObject, UNUserNotificationCenterDelegate {
    let tag: String
    let callsHandler: Bool

    init(tag: String, callsHandler: Bool) {
        self.tag = tag
        self.callsHandler = callsHandler
        super.init()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("%@", "PW_E2E_FAKE willPresent tag=\(tag)")
        if callsHandler {
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .sound])
            } else {
                completionHandler([.alert, .sound])
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("%@", "PW_E2E_FAKE didReceive tag=\(tag)")
        if callsHandler { completionHandler() }
    }
}

/// E2E-only host delegate for the opt-out manual path. When Pushwoosh is told NOT to install its
/// proxy (`Pushwoosh_PLUGIN_NOTIFICATION_HANDLER=YES`), the host app owns the delegate seat and
/// forwards each callback into Pushwoosh's manual API. The `PW_E2E_MANUAL completion …` marker
/// only fires if Pushwoosh actually drives the manual path to completion, so it proves the
/// forward-API works end-to-end under opt-out.
final class PWE2EManualForwardingDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("%@", "PW_E2E_MANUAL willPresent -> forwarding to Pushwoosh")
        Pushwoosh.configure.handleWillPresentNotification(notification) { options in
            NSLog("%@", "PW_E2E_MANUAL completion options=\(options.rawValue)")
            completionHandler(options)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("%@", "PW_E2E_MANUAL didReceive -> forwarding to Pushwoosh")
        Pushwoosh.configure.handleNotificationResponse(response) {
            NSLog("%@", "PW_E2E_MANUAL response completion")
            completionHandler()
        }
    }
}

@main
struct PushwooshSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppGate()
                // Carousel slides carry `pushwoosh://productN` URLs; catch them here and
                // present a product window so a slide tap visibly opens something in the demo.
                .onOpenURL { url in
                    // Let Pushwoosh inspect the URL first (e.g. test-device registration links).
                    _ = PushwooshHelper.safeCall(false) { Pushwoosh.configure.handleOpen(url) }
                    handleCarouselDemoDeepLink(url)
                }
        }
    }
}

// MARK: - Carousel slide deep-link demo

private struct CarouselDemoProduct: Identifiable {
    let number: Int
    let make: String
    let model: String
    let tagline: String
    let imageURL: String
    let power: String
    let zeroToHundred: String
    let topSpeed: String
    let accent: Color
    var id: Int { number }
}

/// Presents a product window for `pushwoosh://product1` / `pushwoosh://product2` (the URLs on the
/// first two carousel slides). Other URLs are ignored so Pushwoosh's own deep-link handling is
/// untouched.
private func handleCarouselDemoDeepLink(_ url: URL) {
    guard url.scheme == "pushwoosh" else { return }
    let key = url.host ?? url.lastPathComponent
    let product: CarouselDemoProduct?
    switch key {
    case "product1":
        product = CarouselDemoProduct(
            number: 1, make: "Koenigsegg", model: "Jesko",
            tagline: "A megacar engineered to chase 500 km/h.",
            imageURL: "https://www.topgear.com/sites/default/files/2021/12/18.%20Koenigsegg%20Jesko.jpeg",
            power: "1,600 hp", zeroToHundred: "2.5 s", topSpeed: "480 km/h",
            accent: Color(red: 1.0, green: 0.45, blue: 0.0))
    case "product2":
        product = CarouselDemoProduct(
            number: 2, make: "McLaren", model: "Artura",
            tagline: "Hybrid V6 supercar with a carbon soul.",
            imageURL: "https://cars-assets-production.mclaren.com/5305/mclaren-artura-mcl39.jpg",
            power: "690 hp", zeroToHundred: "3.0 s", topSpeed: "330 km/h",
            accent: Color(red: 1.0, green: 0.5, blue: 0.1))
    default:
        product = nil
    }
    // Don't present over a controller that's mid-transition (would be silently dropped).
    guard let product, let top = pwDemoTopViewController(), top.presentedViewController == nil else { return }
    let host = UIHostingController(rootView: CarouselDemoView(product: product))
    top.present(host, animated: true)
}

private func pwDemoTopViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
    var top = keyWindow?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
}

private struct CarouselDemoView: View {
    let product: CarouselDemoProduct
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero photo with a fade into the dark background.
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: product.imageURL)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color(.secondarySystemFill)
                        }
                        .frame(maxWidth: .infinity, minHeight: 440, maxHeight: 440)
                        .clipped()
                        .overlay(
                            LinearGradient(colors: [.clear, .clear, .black.opacity(0.95)],
                                           startPoint: .top, endPoint: .bottom)
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.make.uppercased())
                                .font(.caption.weight(.bold))
                                .tracking(2.5)
                                .foregroundStyle(product.accent)
                            Text(product.model)
                                .font(.system(size: 38, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(product.tagline)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Spec strip.
                    HStack(spacing: 0) {
                        specBlock("POWER", product.power)
                        specDivider
                        specBlock("0–100", product.zeroToHundred)
                        specDivider
                        specBlock("TOP SPEED", product.topSpeed)
                    }
                    .padding(.vertical, 26)

                    Button {
                        dismiss()
                    } label: {
                        Text("Configure yours")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(product.accent, in: Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Floating close button on glass.
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(11)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
        }
        .preferredColorScheme(.dark)
    }

    private var specDivider: some View {
        Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 38)
    }

    private func specBlock(_ label: String, _ value: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2.weight(.semibold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Local Pushwoosh server imitation
// Serves the bundled rich media over 127.0.0.1:9595 so the SDK exercises its real server
// pipeline (postEvent -> richmedia response -> zip download -> present) with no external
// processes. Zips are assembled on the fly per variant:
//   showRichMedia       -> campaign pushwoosh.json as-is
//   showRichMediaClient -> style_settings stripped (client configure() API applies)
//   showRichMediaServer -> style_settings replaced with values simulated on the Media screen
final class LocalPushwooshServer {
    static let shared = LocalPushwooshServer()
    static let port: UInt16 = 9595

    // Simulated server-side style_settings; MediaView sets this before postEvent.
    static var simulatedStyleSettings: [String: Any]?

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.pushwoosh.sample.mockserver")
    private var serverVariantTS = 100

    private enum Variant: String {
        case campaign = "A3795-31FA5.zip"
        case client = "A3795-31FA5-client.zip"
        case server = "A3795-31FA5-server.zip"
        case native = "A3795-31FA5-native.zip"

        init?(zipName: String) {
            self.init(rawValue: zipName)
        }
    }

    private static let eventToVariant: [String: Variant] = [
        "showRichMedia": .campaign,
        "showRichMediaClient": .client,
        "showRichMediaServer": .server,
        "showNativeInApp": .native
    ]

    func startIfNeeded() {
        queue.sync {
            guard listener == nil else { return }
            do {
                let params = NWParameters.tcp
                params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: Self.port)!)
                let listener = try NWListener(using: params)
                listener.newConnectionHandler = { [weak self] connection in
                    self?.handle(connection)
                }
                listener.stateUpdateHandler = { state in
                    if case .failed(let error) = state {
                        print("[LocalPushwooshServer] listener failed (port busy?): \(error)")
                    }
                }
                listener.start(queue: queue)
                self.listener = listener
                print("[LocalPushwooshServer] listening on 127.0.0.1:\(Self.port)")
            } catch {
                print("[LocalPushwooshServer] failed to start: \(error)")
            }
        }
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(connection, buffer: Data())
    }

    private func receiveRequest(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            var buffer = buffer
            if let data = data { buffer.append(data) }
            if error != nil { connection.cancel(); return }

            if let request = HTTPRequest(raw: buffer) {
                self.respond(to: request, on: connection)
            } else if isComplete {
                connection.cancel()
            } else {
                self.receiveRequest(connection, buffer: buffer)
            }
        }
    }

    private func respond(to request: HTTPRequest, on connection: NWConnection) {
        let response: (body: Data, contentType: String)
        let method = (request.path as NSString).lastPathComponent

        if request.method == "GET", request.path.hasPrefix("/rm/"), let variant = Variant(zipName: method) {
            let zip = Self.buildZip(for: variant)
            response = (zip, "application/zip")
            print("[LocalPushwooshServer] GET \(request.path) -> \(zip.count) bytes")
        } else if request.method == "POST" && method == "postEvent" {
            let event = ((request.jsonBody?["request"] as? [String: Any])?["event"] as? String) ?? ""
            if let variant = Self.eventToVariant[event] {
                let ts: String
                if variant == .server {
                    serverVariantTS += 1
                    ts = "\(serverVariantTS)"
                } else {
                    ts = "42"
                }
                let url = "http://127.0.0.1:\(Self.port)/rm/\(variant.rawValue)"
                response = (Self.envelope(["richmedia": ["url": url, "ts": ts, "tags": [:]]]), "application/json")
                print("[LocalPushwooshServer] postEvent '\(event)' -> \(variant.rawValue) ts=\(ts)")
            } else {
                response = (Self.envelope([:]), "application/json")
                print("[LocalPushwooshServer] postEvent '\(event)' -> no rich media mapped")
            }
        } else if request.method == "POST" && method == "getInApps" {
            response = (Self.envelope(["inApps": []]), "application/json")
        } else {
            response = (Self.envelope([:]), "application/json")
            print("[LocalPushwooshServer] \(request.method) \(request.path) -> generic OK")
        }

        var head = "HTTP/1.1 200 OK\r\n"
        head += "Content-Type: \(response.contentType)\r\n"
        head += "Content-Length: \(response.body.count)\r\n"
        head += "Connection: close\r\n\r\n"
        var payload = Data(head.utf8)
        payload.append(response.body)
        connection.send(content: payload, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private static func envelope(_ inner: [String: Any]) -> Data {
        let dict: [String: Any] = ["status_code": 200, "status_message": "OK", "response": inner]
        return (try? JSONSerialization.data(withJSONObject: dict)) ?? Data()
    }

    private static func pushwooshJSON(for variant: Variant) -> Data {
        guard let raw = Data(base64Encoded: pushwooshJSONBase64),
              var json = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any] else {
            return Data()
        }
        switch variant {
        case .campaign, .native:
            break
        case .client:
            json.removeValue(forKey: "style_settings")
            json["ios_close_button"] = true
        case .server:
            if let styles = simulatedStyleSettings {
                json["style_settings"] = styles
            } else {
                json.removeValue(forKey: "style_settings")
            }
            json["ios_close_button"] = true
        }
        return (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
    }

    private static func buildZip(for variant: Variant) -> Data {
        var entries: [(name: String, data: Data)] = [
            ("index.html", Data(base64Encoded: indexHTMLBase64) ?? Data()),
            ("pushwoosh.json", pushwooshJSON(for: variant))
        ]
        if variant == .native {
            entries.append(("native-config.json", nativeConfigJSON()))
        }
        return ZipBuilder.archive(entries: entries)
    }

    private static func nativeConfigJSON() -> Data {
        let config: [String: Any] = [
            "displayType": "modal",
            "modal": [
                "showClose": false,
                "dimBackground": false,
                "background": "#FFFFFFFF",
                "title": ["text": "Native In-App ✅", "color": "#111111FF"],
                "message": ["text": "Delivered via postEvent -> ZIP -> native-config.json split.", "color": "#333333FF"],
                "buttons": [
                    ["text": ["text": "Got it", "color": "#111111FF"],
                     "background": "#FFFFFFFF",
                     "border": ["color": "#111111FF", "radius": 12],
                     "action": ["type": "close"]],
                    ["text": ["text": "Open Pushwoosh", "color": "#FFFFFFFF"],
                     "background": "#0E72E5FF",
                     "border": ["color": "#0E72E5FF", "radius": 12],
                     "action": ["type": "url", "url": "https://www.pushwoosh.com"]]
                ]
            ]
        ]
        return (try? JSONSerialization.data(withJSONObject: config)) ?? Data()
    }

    private struct HTTPRequest {
        let method: String
        let path: String
        let body: Data

        var jsonBody: [String: Any]? {
            (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
        }

        init?(raw: Data) {
            guard let headerEnd = raw.range(of: Data("\r\n\r\n".utf8)) else { return nil }
            let headerText = String(decoding: raw[..<headerEnd.lowerBound], as: UTF8.self)
            let lines = headerText.components(separatedBy: "\r\n")
            let requestLine = lines.first?.components(separatedBy: " ") ?? []
            guard requestLine.count >= 2 else { return nil }

            var contentLength = 0
            for line in lines.dropFirst() where line.lowercased().hasPrefix("content-length:") {
                contentLength = Int(line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)) ?? 0
            }

            let bodyData = raw[headerEnd.upperBound...]
            guard bodyData.count >= contentLength else { return nil }

            self.method = requestLine[0]
            self.path = requestLine[1]
            self.body = Data(bodyData.prefix(contentLength))
        }
    }

    private static let indexHTMLBase64 = "CiAgICAgIDwhRE9DVFlQRSBodG1sPgogICAgICA8aHRtbCBsYW5nPSJlbiI+CiAgICAgICAgPGhlYWQ+CiAgICAgICAgICA8bWV0YSBjaGFyc2V0PSJVVEYtOCI+CiAgICAgICAgICA8bWV0YSBodHRwLWVxdWl2PSJYLVVBLUNvbXBhdGlibGUiIGNvbnRlbnQ9IklFPWVkZ2UiPgogICAgICAgICAgPG1ldGEgbmFtZT0idmlld3BvcnQiIGNvbnRlbnQ9IndpZHRoPWRldmljZS13aWR0aCwgaW5pdGlhbC1zY2FsZT0xLjAiPgogICAgICAgICAgPHN0eWxlPgogICAgICAgICAgICAudS1wb3B1cC1jb250YWluZXIgLnUtcG9wdXAtaGVhZGVyLCAudS1wb3B1cC1jb250YWluZXIgLnUtcG9wdXAtZm9vdGVyIHsKICAgICAgICAgICAgICBtYXgtd2lkdGg6IDEwMCUgIWltcG9ydGFudDsKICAgICAgICAgICAgfQogICAgICAgICAgPC9zdHlsZT4KICAgICAgICAgIDxzdHlsZT4KICAgICAgICAgICAgLmNhcm91c2VsLWNvbnRhaW5lciB7CiAgICAgICAgICAgICAgcG9zaXRpb246IHJlbGF0aXZlOwogICAgICAgICAgICAgIG1heC13aWR0aDogNjAwcHg7CiAgICAgICAgICAgICAgbWFyZ2luOiBhdXRvOwogICAgICAgICAgICB9CgogICAgICAgICAgICAuY2Fyb3VzZWwtbWFpbiB7CiAgICAgICAgICAgICAgcG9zaXRpb246IHJlbGF0aXZlOwogICAgICAgICAgICAgIG92ZXJmbG93OiBoaWRkZW47CiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIC5jYXJvdXNlbC1tYWluIC5tYWluLWltYWdlIHsKICAgICAgICAgICAgICBwb3NpdGlvbjogYWJzb2x1dGU7CiAgICAgICAgICAgICAgd2lkdGg6IDEwMCU7CiAgICAgICAgICAgICAgaGVpZ2h0OiBhdXRvOwogICAgICAgICAgICAgIG9wYWNpdHk6IDA7CiAgICAgICAgICAgICAgdHJhbnNpdGlvbjogb3BhY2l0eSAwLjFzIGVhc2UtaW4tb3V0LCB0cmFuc2Zvcm0gMC4xcyBlYXNlLWluLW91dDsKICAgICAgICAgICAgfQoKICAgICAgICAgICAgLmNhcm91c2VsLW1haW4gLm1haW4taW1hZ2UuYWN0aXZlIHsKICAgICAgICAgICAgICBvcGFjaXR5OiAxOwogICAgICAgICAgICAgIHBvc2l0aW9uOiByZWxhdGl2ZTsKICAgICAgICAgICAgfQoKICAgICAgICAgICAgLmNhcm91c2VsLXByZXZpZXdzIHsKICAgICAgICAgICAgICB0ZXh0LWFsaWduOiBsZWZ0OwogICAgICAgICAgICAgIG1hcmdpbjogNHB4IC0ycHg7CiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIC5jYXJvdXNlbC1wcmV2aWV3cyAucHJldmlldyB7CiAgICAgICAgICAgICAgY3Vyc29yOiBwb2ludGVyOwogICAgICAgICAgICAgIHdpZHRoOiAxMDBweDsKICAgICAgICAgICAgICBtaW4td2lkdGg6IDEwMHB4OwogICAgICAgICAgICAgIGhlaWdodDogYXV0bzsKICAgICAgICAgICAgICBtYXJnaW46IDJweDsKICAgICAgICAgICAgICBvcGFjaXR5OiAwLjY7CiAgICAgICAgICAgICAgYm9yZGVyOiAxcHggc29saWQgcmdiYSgwLCAwLCAwLCAwLjMpOwogICAgICAgICAgICB9CgogICAgICAgICAgICAuY2Fyb3VzZWwtcHJldmlld3MgLnByZXZpZXcuYWN0aXZlIHsKICAgICAgICAgICAgICBvcGFjaXR5OiAxOwogICAgICAgICAgICAgIGJvcmRlcjogMnB4IHNvbGlkICMwMDAwZWU7CiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIC5wcmV2LAogICAgICAgICAgICAubmV4dCB7CiAgICAgICAgICAgICAgcG9zaXRpb246IGFic29sdXRlOwogICAgICAgICAgICAgIHRvcDogNTAlOwogICAgICAgICAgICAgIHdpZHRoOiAzNHB4OwogICAgICAgICAgICAgIGhlaWdodDogMzRweDsKICAgICAgICAgICAgICBiYWNrZ3JvdW5kLXNpemU6IDE4cHggMThweDsKICAgICAgICAgICAgICBib3JkZXItcmFkaXVzOiAycHg7CiAgICAgICAgICAgICAgYmFja2dyb3VuZC1jb2xvcjogcmdiYSgwLCAwLCAwLCAwLjUpOwogICAgICAgICAgICAgIGJhY2tncm91bmQtcG9zaXRpb246IDUwJSA1MCU7CiAgICAgICAgICAgICAgYmFja2dyb3VuZC1yZXBlYXQ6IG5vLXJlcGVhdDsKICAgICAgICAgICAgICB0cmFuc2Zvcm06IHRyYW5zbGF0ZVkoLTUwJSk7CiAgICAgICAgICAgICAgei1pbmRleDogMTAxOwogICAgICAgICAgICAgIGN1cnNvcjogcG9pbnRlcjsKICAgICAgICAgICAgfQoKICAgICAgICAgICAgLnByZXYgewogICAgICAgICAgICAgIGxlZnQ6IDE2cHg7CiAgICAgICAgICAgICAgYmFja2dyb3VuZC1pbWFnZTogdXJsKCJkYXRhOmltYWdlL3N2Zyt4bWw7Y2hhcnNldD11dGYtOCwlM0NzdmcgeG1sbnM9J2h0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnJyB3aWR0aD0nMTgnIGhlaWdodD0nMTgnIGZpbGw9JyUyM2ZmZiclM0UlM0NwYXRoIGQ9J00xNSA4LjI1SDUuODdsNC4xOS00LjE5TDkgMyAzIDlsNiA2IDEuMDYtMS4wNi00LjE5LTQuMTlIMTV2LTEuNXonLyUzRSUzQy9zdmclM0UiKTsKICAgICAgICAgICAgfQoKICAgICAgICAgICAgLm5leHQgewogICAgICAgICAgICAgIHJpZ2h0OiAxNnB4OwogICAgICAgICAgICAgIGJhY2tncm91bmQtaW1hZ2U6IHVybCgiZGF0YTppbWFnZS9zdmcreG1sO2NoYXJzZXQ9dXRmLTgsJTNDc3ZnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zycgd2lkdGg9JzE4JyBoZWlnaHQ9JzE4JyBmaWxsPSclMjNmZmYnJTNFJTNDcGF0aCBkPSdNOSAzTDcuOTQgNC4wNmw0LjE5IDQuMTlIM3YxLjVoOS4xM2wtNC4xOSA0LjE5TDkgMTVsNi02eicvJTNFJTNDL3N2ZyUzRSIpOwogICAgICAgICAgICB9CgogICAgICAgICAgICBAa2V5ZnJhbWVzIHNsaWRlSW5Gcm9tUmlnaHQgewogICAgICAgICAgICAgIGZyb20gewogICAgICAgICAgICAgICAgdHJhbnNmb3JtOiB0cmFuc2xhdGVYKDEwMCUpOwogICAgICAgICAgICAgICAgb3BhY2l0eTogMDsKICAgICAgICAgICAgICB9CgogICAgICAgICAgICAgIHRvIHsKICAgICAgICAgICAgICAgIHRyYW5zZm9ybTogdHJhbnNsYXRlWCgwKTsKICAgICAgICAgICAgICAgIG9wYWNpdHk6IDE7CiAgICAgICAgICAgICAgfQogICAgICAgICAgICB9CgogICAgICAgICAgICBAa2V5ZnJhbWVzIHNsaWRlT3V0VG9MZWZ0IHsKICAgICAgICAgICAgICBmcm9tIHsKICAgICAgICAgICAgICAgIHRyYW5zZm9ybTogdHJhbnNsYXRlWCgwKTsKICAgICAgICAgICAgICAgIG9wYWNpdHk6IDE7CiAgICAgICAgICAgICAgfQoKICAgICAgICAgICAgICB0byB7CiAgICAgICAgICAgICAgICB0cmFuc2Zvcm06IHRyYW5zbGF0ZVgoLTEwMCUpOwogICAgICAgICAgICAgICAgb3BhY2l0eTogMDsKICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIEBrZXlmcmFtZXMgc2xpZGVJbkZyb21MZWZ0IHsKICAgICAgICAgICAgICBmcm9tIHsKICAgICAgICAgICAgICAgIHRyYW5zZm9ybTogdHJhbnNsYXRlWCgtMTAwJSk7CiAgICAgICAgICAgICAgICBvcGFjaXR5OiAwOwogICAgICAgICAgICAgIH0KCiAgICAgICAgICAgICAgdG8gewogICAgICAgICAgICAgICAgdHJhbnNmb3JtOiB0cmFuc2xhdGVYKDApOwogICAgICAgICAgICAgICAgb3BhY2l0eTogMTsKICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIEBrZXlmcmFtZXMgc2xpZGVPdXRUb1JpZ2h0IHsKICAgICAgICAgICAgICBmcm9tIHsKICAgICAgICAgICAgICAgIHRyYW5zZm9ybTogdHJhbnNsYXRlWCgwKTsKICAgICAgICAgICAgICAgIG9wYWNpdHk6IDE7CiAgICAgICAgICAgICAgfQoKICAgICAgICAgICAgICB0byB7CiAgICAgICAgICAgICAgICB0cmFuc2Zvcm06IHRyYW5zbGF0ZVgoMTAwJSk7CiAgICAgICAgICAgICAgICBvcGFjaXR5OiAwOwogICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQoKICAgICAgICAgICAgLnNsaWRlLWluLXJpZ2h0IHsKICAgICAgICAgICAgICBhbmltYXRpb246IHNsaWRlSW5Gcm9tUmlnaHQgMC4xcyBlYXNlLWluLW91dCBmb3J3YXJkczsKICAgICAgICAgICAgfQoKICAgICAgICAgICAgLnNsaWRlLW91dC1sZWZ0IHsKICAgICAgICAgICAgICBhbmltYXRpb246IHNsaWRlT3V0VG9MZWZ0IDAuMXMgZWFzZS1pbi1vdXQgZm9yd2FyZHM7CiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIC5zbGlkZS1pbi1sZWZ0IHsKICAgICAgICAgICAgICBhbmltYXRpb246IHNsaWRlSW5Gcm9tTGVmdCAwLjFzIGVhc2UtaW4tb3V0IGZvcndhcmRzOwogICAgICAgICAgICB9CgogICAgICAgICAgICAuc2xpZGUtb3V0LXJpZ2h0IHsKICAgICAgICAgICAgICBhbmltYXRpb246IHNsaWRlT3V0VG9SaWdodCAwLjFzIGVhc2UtaW4tb3V0IGZvcndhcmRzOwogICAgICAgICAgICB9CiAgICAgICAgICA8L3N0eWxlPgogICAgICAgIDwvaGVhZD4KICAgICAgICA8Ym9keT4KICAgICAgICAgIDxkaXYgY2xhc3M9InUtcG9wdXAtY29udGFpbmVyIj4KICA8ZGl2IGNsYXNzPSJ1LXBvcHVwLW92ZXJsYXkiPjwvZGl2PgoKICAKCiAgCgogIAogIDxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI+CiAgICAKICAgICAgLnUtcG9wdXAtY29udGFpbmVyIC51LXJvdyB7CiAgICAgICAgZGlzcGxheTogZmxleDsKICAgICAgICBmbGV4LXdyYXA6IG5vd3JhcDsKICAgICAgICBtYXJnaW4tbGVmdDogMDsKICAgICAgICBtYXJnaW4tcmlnaHQ6IDA7CiAgICAgIH0KCiAgICAgIC51LXBvcHVwLWNvbnRhaW5lciAudS1yb3cgLnUtY29sIHsKICAgICAgICBwb3NpdGlvbjogcmVsYXRpdmU7CiAgICAgICAgd2lkdGg6IDEwMCU7CiAgICAgICAgcGFkZGluZy1yaWdodDogMDsKICAgICAgICBwYWRkaW5nLWxlZnQ6IDA7CiAgICAgIH0KCiAgICAgIAogICAgICAgICAgLnUtcG9wdXAtY29udGFpbmVyIC51LXJvdyAudS1jb2wudS1jb2wtMTAwIHsKICAgICAgICAgICAgZmxleDogMCAwIDEwMCU7CiAgICAgICAgICAgIG1heC13aWR0aDogMTAwJTsKICAgICAgICAgIH0KICAgICAgICAKCiAgICAgIAogICAgICAgICAgICBAbWVkaWEgKG1heC13aWR0aDogNDgwcHgpIHsKICAgICAgICAgICAgICAudS1wb3B1cC1jb250YWluZXIgLmNvbnRhaW5lciB7CiAgICAgICAgICAgICAgICBtYXgtd2lkdGg6IDEwMCUgIWltcG9ydGFudDsKICAgICAgICAgICAgICB9CgogICAgICAgICAgICAgIC51LXBvcHVwLWNvbnRhaW5lciAudS1yb3c6bm90KC5uby1zdGFjaykgewogICAgICAgICAgICAgICAgZmxleC13cmFwOiB3cmFwOwogICAgICAgICAgICAgIH0KCiAgICAgICAgICAgICAgLnUtcG9wdXAtY29udGFpbmVyIC51LXJvdzpub3QoLm5vLXN0YWNrKSAudS1jb2wgewogICAgICAgICAgICAgICAgZmxleDogMCAwIDEwMCUgIWltcG9ydGFudDsKICAgICAgICAgICAgICAgIG1heC13aWR0aDogMTAwJSAhaW1wb3J0YW50OwogICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQogICAgICAgICAgCiAgICAKLnUtcG9wdXAtY29udGFpbmVyIHB7bWFyZ2luOjB9LnUtcG9wdXAtY29udGFpbmVyIC5lcnJvci1maWVsZHstd2Via2l0LWFuaW1hdGlvbi1kdXJhdGlvbjoxczthbmltYXRpb24tZHVyYXRpb246MXM7LXdlYmtpdC1hbmltYXRpb24tZmlsbC1tb2RlOmJvdGg7YW5pbWF0aW9uLWZpbGwtbW9kZTpib3RoOy13ZWJraXQtYW5pbWF0aW9uLW5hbWU6c2hha2U7YW5pbWF0aW9uLW5hbWU6c2hha2V9LnUtcG9wdXAtY29udGFpbmVyIC5lcnJvci1maWVsZCBpbnB1dCwudS1wb3B1cC1jb250YWluZXIgLmVycm9yLWZpZWxkIHRleHRhcmVhe2JvcmRlci1jb2xvcjojYTk0NDQyIWltcG9ydGFudDtjb2xvcjojYTk0NDQyIWltcG9ydGFudH0udS1wb3B1cC1jb250YWluZXIgLmZpZWxkLWVycm9ye2ZvbnQtc2l6ZToxNHB4O2ZvbnQtd2VpZ2h0OjcwMDtwYWRkaW5nOjVweCAxMHB4O3Bvc2l0aW9uOmFic29sdXRlO3JpZ2h0OjEwcHg7dG9wOi0yMHB4fS51LXBvcHVwLWNvbnRhaW5lciAuZmllbGQtZXJyb3I6YWZ0ZXJ7Ym9yZGVyOnNvbGlkIHRyYW5zcGFyZW50O2JvcmRlci1jb2xvcjojZWJjY2NjIHJnYmEoMTM2LDE4MywyMTMsMCkgcmdiYSgxMzYsMTgzLDIxMywwKTtib3JkZXItd2lkdGg6NXB4O2NvbnRlbnQ6IiAiO2hlaWdodDowO2xlZnQ6NTAlO21hcmdpbi1sZWZ0Oi01cHg7cG9pbnRlci1ldmVudHM6bm9uZTtwb3NpdGlvbjphYnNvbHV0ZTt0b3A6MTAwJTt3aWR0aDowfS51LXBvcHVwLWNvbnRhaW5lciAuc3Bpbm5lcnttYXJnaW46MCBhdXRvO3RleHQtYWxpZ246Y2VudGVyO3dpZHRoOjcwcHh9LnUtcG9wdXAtY29udGFpbmVyIC5zcGlubmVyPmRpdnstd2Via2l0LWFuaW1hdGlvbjpzay1ib3VuY2VkZWxheSAxLjRzIGVhc2UtaW4tb3V0IGluZmluaXRlIGJvdGg7YW5pbWF0aW9uOnNrLWJvdW5jZWRlbGF5IDEuNHMgZWFzZS1pbi1vdXQgaW5maW5pdGUgYm90aDtiYWNrZ3JvdW5kLWNvbG9yOmhzbGEoMCwwJSwxMDAlLC41KTtib3JkZXItcmFkaXVzOjEwMCU7ZGlzcGxheTppbmxpbmUtYmxvY2s7aGVpZ2h0OjEycHg7bWFyZ2luOjAgMnB4O3dpZHRoOjEycHh9LnUtcG9wdXAtY29udGFpbmVyIC5zcGlubmVyIC5ib3VuY2Uxey13ZWJraXQtYW5pbWF0aW9uLWRlbGF5Oi0uMzJzO2FuaW1hdGlvbi1kZWxheTotLjMyc30udS1wb3B1cC1jb250YWluZXIgLnNwaW5uZXIgLmJvdW5jZTJ7LXdlYmtpdC1hbmltYXRpb24tZGVsYXk6LS4xNnM7YW5pbWF0aW9uLWRlbGF5Oi0uMTZzfUAtd2Via2l0LWtleWZyYW1lcyBzay1ib3VuY2VkZWxheXswJSw4MCUsdG97LXdlYmtpdC10cmFuc2Zvcm06c2NhbGUoMCl9NDAley13ZWJraXQtdHJhbnNmb3JtOnNjYWxlKDEpfX1Aa2V5ZnJhbWVzIHNrLWJvdW5jZWRlbGF5ezAlLDgwJSx0b3std2Via2l0LXRyYW5zZm9ybTpzY2FsZSgwKTt0cmFuc2Zvcm06c2NhbGUoMCl9NDAley13ZWJraXQtdHJhbnNmb3JtOnNjYWxlKDEpO3RyYW5zZm9ybTpzY2FsZSgxKX19QC13ZWJraXQta2V5ZnJhbWVzIHNoYWtlezAlLHRvey13ZWJraXQtdHJhbnNmb3JtOnRyYW5zbGF0ZVooMCk7dHJhbnNmb3JtOnRyYW5zbGF0ZVooMCl9MTAlLDMwJSw1MCUsNzAlLDkwJXstd2Via2l0LXRyYW5zZm9ybTp0cmFuc2xhdGUzZCgtMTBweCwwLDApO3RyYW5zZm9ybTp0cmFuc2xhdGUzZCgtMTBweCwwLDApfTIwJSw0MCUsNjAlLDgwJXstd2Via2l0LXRyYW5zZm9ybTp0cmFuc2xhdGUzZCgxMHB4LDAsMCk7dHJhbnNmb3JtOnRyYW5zbGF0ZTNkKDEwcHgsMCwwKX19QGtleWZyYW1lcyBzaGFrZXswJSx0b3std2Via2l0LXRyYW5zZm9ybTp0cmFuc2xhdGVaKDApO3RyYW5zZm9ybTp0cmFuc2xhdGVaKDApfTEwJSwzMCUsNTAlLDcwJSw5MCV7LXdlYmtpdC10cmFuc2Zvcm06dHJhbnNsYXRlM2QoLTEwcHgsMCwwKTt0cmFuc2Zvcm06dHJhbnNsYXRlM2QoLTEwcHgsMCwwKX0yMCUsNDAlLDYwJSw4MCV7LXdlYmtpdC10cmFuc2Zvcm06dHJhbnNsYXRlM2QoMTBweCwwLDApO3RyYW5zZm9ybTp0cmFuc2xhdGUzZCgxMHB4LDAsMCl9fS51LXBvcHVwLWNvbnRhaW5lciAuY29udGFpbmVyey0tYnMtZ3V0dGVyLXg6MHB4Oy0tYnMtZ3V0dGVyLXk6MDttYXJnaW4tbGVmdDphdXRvO21hcmdpbi1yaWdodDphdXRvO3BhZGRpbmctbGVmdDpjYWxjKHZhcigtLWJzLWd1dHRlci14KSouNSk7cGFkZGluZy1yaWdodDpjYWxjKHZhcigtLWJzLWd1dHRlci14KSouNSk7d2lkdGg6MTAwJX0KCi51LXBvcHVwLWNvbnRhaW5lciBhW29uY2xpY2tde2N1cnNvcjpwb2ludGVyfQoKCiAgICAgIAoKICAgICAgCiAgICAgICAgICBAbWVkaWEgKG1heC13aWR0aDogNDgwcHgpIHsKICAgICAgICAgICAgLnUtcG9wdXAtY29udGFpbmVyIC5oaWRlLW1vYmlsZSB7CiAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgZGlzcGxheTogbm9uZSAhaW1wb3J0YW50OwogICAgICAgICAgICB9CiAgICAgICAgICB9CiAgICAgICAgICAKCiAgICAgICAgICBAbWVkaWEgKG1pbi13aWR0aDogNDgxcHgpIHsKICAgICAgICAgICAgLnUtcG9wdXAtY29udGFpbmVyIC5oaWRlLWRlc2t0b3AgewogICAgICAgICAgICAgIAogICAgICAgICAgICAgIGRpc3BsYXk6IG5vbmUgIWltcG9ydGFudDsKICAgICAgICAgICAgfQogICAgICAgICAgfQoudS1wb3B1cC1jb250YWluZXIgYSB7IGNvbG9yOiAjMDAwMGVlOyB0ZXh0LWRlY29yYXRpb246IHVuZGVybGluZTsgfSAjdV9ib2R5IGE6aG92ZXIgeyBjb2xvcjogIzAwMDBlZTsgdGV4dC1kZWNvcmF0aW9uOiB1bmRlcmxpbmU7IH0gLnUtcG9wdXAtY29udGFpbmVyIHsgcG9zaXRpb246IGFic29sdXRlOyBsZWZ0OiAwOyByaWdodDogMDsgYm90dG9tOiAwOyB0b3A6IDA7IGRpc3BsYXk6IGZsZXg7IGZsZXgtZGlyZWN0aW9uOiBjb2x1bW47IH0gLnUtcG9wdXAtY29udGFpbmVyIC51LXBvcHVwLW92ZXJsYXkgeyBwb3NpdGlvbjogZml4ZWQ7IGxlZnQ6IDA7IHJpZ2h0OiAwOyBib3R0b206IDA7IHRvcDogMDsgYmFja2dyb3VuZC1jb2xvcjogcmdiYSgwLCAwLCAwLCAwLjEpOyB6LWluZGV4OiA5ODsgfSAudS1wb3B1cC1jb250YWluZXIgLnUtcG9wdXAtbWFpbiB7IHdpZHRoOiAxMDAlOyBtYXgtd2lkdGg6IDYwMHB4OyBoZWlnaHQ6IGF1dG87IG1hcmdpbjogYXV0bzsgei1pbmRleDogOTk7IH0gLnUtcG9wdXAtY29udGFpbmVyIC51LXBvcHVwLWhlYWRlciwgLnUtcG9wdXAtY29udGFpbmVyIC51LXBvcHVwLWZvb3RlciB7IHBvc2l0aW9uOiByZWxhdGl2ZTsgd2lkdGg6IDEwMCU7IG1heC13aWR0aDogNjAwcHg7IG1hcmdpbjogYXV0bzsgfSAudS1wb3B1cC1jb250YWluZXIgLnUtcG9wdXAtY29udGVudCB7IGhlaWdodDogMTAwJTsgb3ZlcmZsb3cteTogaW5oZXJpdDsgfSAudS1wb3B1cC1jb250YWluZXIgLnUtY2xvc2UtYnV0dG9uIHsgcG9zaXRpb246IGFic29sdXRlOyB0b3A6IDBweDsgcmlnaHQ6IDBweDsgZGlzcGxheTogZmxleDsgZmxleC1mbG93OiBjb2x1bW4gbm93cmFwOyBqdXN0aWZ5LWNvbnRlbnQ6IGNlbnRlcjsgYWxpZ24taXRlbXM6IGNlbnRlcjsgbWFyZ2luOiAxNHB4IDE1cHggMHB4IDBweDsgcGFkZGluZzogMHB4OyB3aWR0aDogNDBweDsgaGVpZ2h0OiA0MHB4OyBiYWNrZ3JvdW5kLWNvbG9yOiB0cmFuc3BhcmVudDsgYm9yZGVyOiAwOyBib3JkZXItcmFkaXVzOiAwcHg7IGN1cnNvcjogcG9pbnRlcjsgei1pbmRleDogOTk7IH0gLnUtcG9wdXAtY29udGFpbmVyIC51LWNsb3NlLWJ1dHRvbiAuaWNvbi1jcm9zcyB7IG1hcmdpbjogMDsgcGFkZGluZzogMDsgYm9yZGVyOiAwOyBiYWNrZ3JvdW5kOiBub25lOyBwb3NpdGlvbjogcmVsYXRpdmU7IHdpZHRoOiAyMHB4OyBoZWlnaHQ6IDIwcHg7IH0gLnUtcG9wdXAtY29udGFpbmVyIC51LWNsb3NlLWJ1dHRvbiAuaWNvbi1jcm9zczpiZWZvcmUsIC51LXBvcHVwLWNvbnRhaW5lciAudS1jbG9zZS1idXR0b24gLmljb24tY3Jvc3M6YWZ0ZXIgeyBjb250ZW50OiAiIjsgcG9zaXRpb246IGFic29sdXRlOyB0b3A6IDhweDsgbGVmdDogMDsgcmlnaHQ6IDA7IGhlaWdodDogM3B4OyBiYWNrZ3JvdW5kLWNvbG9yOiByZ2JhKDI1LDI1LDI1LDAuOSk7IGJvcmRlci1yYWRpdXM6IDZweDsgfSAudS1wb3B1cC1jb250YWluZXIgLnUtY2xvc2UtYnV0dG9uIC5pY29uLWNyb3NzOmJlZm9yZSB7IHRyYW5zZm9ybTogcm90YXRlKDQ1ZGVnKTsgfSAudS1wb3B1cC1jb250YWluZXIgLnUtY2xvc2UtYnV0dG9uIC5pY29uLWNyb3NzOmFmdGVyIHsgdHJhbnNmb3JtOiByb3RhdGUoLTQ1ZGVnKTsgfSAjdV9jb250ZW50X2J1dHRvbl8xIGE6aG92ZXIgeyBjb2xvcjogI0ZGRkZGRiAhaW1wb3J0YW50OyBiYWNrZ3JvdW5kLWNvbG9yOiAjM0FBRUUwICFpbXBvcnRhbnQ7IH0KICA8L3N0eWxlPgogIAoKICAKCiAgCjxkaXYgY2xhc3M9InUtcG9wdXAtbWFpbiI+CiAgCiAgICA8ZGl2IGNsYXNzPSJ1LXBvcHVwLWhlYWRlciI+CiAgICAgIAogIDxhIGhyZWY9IiMiIG9uQ2xpY2s9IndpbmRvdz8ucHVzaHdvb3NoPy5jbG9zZUluQXBwKCk7IiBjbGFzcz0idS1jbG9zZS1idXR0b24iPgogICAgPHNwYW4gY2xhc3M9Imljb24tY3Jvc3MiPjwvc3Bhbj4KICA8L2E+CgogICAgPC9kaXY+CiAgCgogIDxkaXYgY2xhc3M9InUtcG9wdXAtY29udGVudCI+CiAgICA8ZGl2CiAgICAgIGlkPSJ1X2JvZHkiCiAgICAgIGNsYXNzPSJ1X2JvZHkiCiAgICAgIHN0eWxlPSJkaXNwbGF5OiBmbGV4OyBmbGV4LWRpcmVjdGlvbjogY29sdW1uOyBqdXN0aWZ5LWNvbnRlbnQ6IGNlbnRlcjtjb2xvcjogIzAwMDAwMDtiYWNrZ3JvdW5kLWNvbG9yOiAjZmZmZmZmO2ZvbnQtZmFtaWx5OiBhcmlhbCxoZWx2ZXRpY2Esc2Fucy1zZXJpZjtmb250LXdlaWdodDogNDAwOyBiYWNrZ3JvdW5kLWltYWdlOiB1cmwoJ2h0dHBzOi8vYXNzZXRzLnVubGF5ZXIuY29tL3Byb2plY3RzLzEwMTgvMTcwNzIxNzcxNzAzOS1MdXh4ZWxlLnBuZycpO2JhY2tncm91bmQtcmVwZWF0OiBuby1yZXBlYXQ7YmFja2dyb3VuZC1wb3NpdGlvbjogMHB4IDBweDtiYWNrZ3JvdW5kLXNpemU6IGNvbnRhaW47IGJvcmRlci1yYWRpdXM6IDIwcHg7Ij4KICAgICAgCiAgPGRpdiBpZD0idV9yb3dfMSIgY2xhc3M9InVfcm93IHYtcm93LXBhZGRpbmcgdi1yb3ctYmFja2dyb3VuZC1pbWFnZS0tb3V0ZXIgdi1yb3ctYmFja2dyb3VuZC1jb2xvciIgc3R5bGU9InBhZGRpbmc6IDBweDsiPgogICAgPGRpdiBjbGFzcz0iY29udGFpbmVyIHYtcm93LWJhY2tncm91bmQtaW1hZ2UtLWlubmVyIHYtcm93LWNvbHVtbnMtYmFja2dyb3VuZC1jb2xvci1iYWNrZ3JvdW5kLWNvbG9yIiBzdHlsZT0ibWF4LXdpZHRoOiA1MDBweDttYXJnaW46IDAgYXV0bzsiPgogICAgICA8ZGl2IGNsYXNzPSJ1LXJvdyB2LXJvdy1hbGlnbi1pdGVtcyI+CiAgICAgICAgCjxkaXYgaWQ9InVfY29sdW1uXzEiIGNsYXNzPSJ1LWNvbCB1LWNvbC0xMDAgdV9jb2x1bW4gdi1yb3ctYWxpZ24taXRlbXMgdi1jb2wtYmFja2dyb3VuZC1jb2xvciB2LWNvbC1ib3JkZXIgdi1jb2wtYm9yZGVyLXJhZGl1cyIgc3R5bGU9ImRpc3BsYXk6ZmxleDtiYWNrZ3JvdW5kLWNvbG9yOnRyYW5zcGFyZW50O2JvcmRlci10b3A6IDBweCBzb2xpZCB0cmFuc3BhcmVudDtib3JkZXItbGVmdDogMHB4IHNvbGlkIHRyYW5zcGFyZW50O2JvcmRlci1yaWdodDogMHB4IHNvbGlkIHRyYW5zcGFyZW50O2JvcmRlci1ib3R0b206IDBweCBzb2xpZCB0cmFuc3BhcmVudDsiPgogIDxkaXYgY2xhc3M9InYtY29sLXBhZGRpbmciIHN0eWxlPSJ3aWR0aDogMTAwJTtwYWRkaW5nOjBweDsiPgogICAgCiAgPGRpdiBpZD0idV9jb250ZW50X3RleHRfMSIgY2xhc3M9InVfY29udGVudF90ZXh0IHYtY29udGFpbmVyLXBhZGRpbmctcGFkZGluZyIgc3R5bGU9Im92ZXJmbG93LXdyYXA6IGJyZWFrLXdvcmQ7cGFkZGluZzogMjIwcHggMTRweCAxMnB4OyI+CiAgICAKICA8ZGl2IGNsYXNzPSJ2LWNvbG9yIHYtdGV4dC1hbGlnbiB2LWxpbmUtaGVpZ2h0IHYtZm9udC13ZWlnaHQgdi1mb250LWZhbWlseSB2LWZvbnQtc2l6ZSB2LWxldHRlci1zcGFjaW5nIiBzdHlsZT0iZm9udC1zaXplOiAxNnB4OyBjb2xvcjogIzAwMDAwMDsgbGluZS1oZWlnaHQ6IDE1MCU7IHRleHQtYWxpZ246IGNlbnRlcjsgd29yZC13cmFwOiBicmVhay13b3JkOyI+CiAgICB7e054NnNGbmk0alYudGV4dHx0ZXh0fH19CiAgPC9kaXY+CgogIDwvZGl2PgoKICA8L2Rpdj4KPC9kaXY+CgogICAgICA8L2Rpdj4KICAgIDwvZGl2PgogIDwvZGl2PgoKICA8ZGl2IGlkPSJ1X3Jvd18zIiBjbGFzcz0idV9yb3cgdi1yb3ctcGFkZGluZyB2LXJvdy1iYWNrZ3JvdW5kLWltYWdlLS1vdXRlciB2LXJvdy1iYWNrZ3JvdW5kLWNvbG9yIiBzdHlsZT0icGFkZGluZzogMHB4OyI+CiAgICA8ZGl2IGNsYXNzPSJjb250YWluZXIgdi1yb3ctYmFja2dyb3VuZC1pbWFnZS0taW5uZXIgdi1yb3ctY29sdW1ucy1iYWNrZ3JvdW5kLWNvbG9yLWJhY2tncm91bmQtY29sb3IiIHN0eWxlPSJtYXgtd2lkdGg6IDUwMHB4O21hcmdpbjogMCBhdXRvOyI+CiAgICAgIDxkaXYgY2xhc3M9InUtcm93IHYtcm93LWFsaWduLWl0ZW1zIj4KICAgICAgICAKPGRpdiBpZD0idV9jb2x1bW5fMyIgY2xhc3M9InUtY29sIHUtY29sLTEwMCB1X2NvbHVtbiB2LXJvdy1hbGlnbi1pdGVtcyB2LWNvbC1iYWNrZ3JvdW5kLWNvbG9yIHYtY29sLWJvcmRlciB2LWNvbC1ib3JkZXItcmFkaXVzIiBzdHlsZT0iZGlzcGxheTpmbGV4O2JhY2tncm91bmQtY29sb3I6dHJhbnNwYXJlbnQ7Ym9yZGVyLXRvcDogMHB4IHNvbGlkIHRyYW5zcGFyZW50O2JvcmRlci1sZWZ0OiAwcHggc29saWQgdHJhbnNwYXJlbnQ7Ym9yZGVyLXJpZ2h0OiAwcHggc29saWQgdHJhbnNwYXJlbnQ7Ym9yZGVyLWJvdHRvbTogMHB4IHNvbGlkIHRyYW5zcGFyZW50O2JvcmRlci1yYWRpdXM6IDBweCAwcHggMjBweCAyMHB4OyI+CiAgPGRpdiBjbGFzcz0idi1jb2wtcGFkZGluZyIgc3R5bGU9IndpZHRoOiAxMDAlO3BhZGRpbmc6MHB4OyI+CiAgICAKICA8ZGl2IGlkPSJ1X2NvbnRlbnRfYnV0dG9uXzEiIGNsYXNzPSJ1X2NvbnRlbnRfYnV0dG9uIHYtY29udGFpbmVyLXBhZGRpbmctcGFkZGluZyIgc3R5bGU9Im92ZXJmbG93LXdyYXA6IGJyZWFrLXdvcmQ7cGFkZGluZzogMjBweCAxMHB4IDYwcHg7Ij4KICAgIAo8ZGl2IGNsYXNzPSJ2LXRleHQtYWxpZ24iIHN0eWxlPSJ0ZXh0LWFsaWduOiBjZW50ZXI7Ij4KICA8YSBocmVmPSJ7e01fQU4xWENIc0wuaHJlZi52YWx1ZXMuaHJlZnx0ZXh0fH19IiB0YXJnZXQ9Il9ibGFuayIgb25jbGljaz0id2luZG93LnB1c2h3b29zaC5vcGVuQXBwU2V0dGluZ3MoKSIgY2xhc3M9InYtc2l6ZS13aWR0aCB2LWxpbmUtaGVpZ2h0IHYtcGFkZGluZyB2LWJ1dHRvbi1jb2xvcnMgdi1ib3JkZXIgdi1ib3JkZXItcmFkaXVzIHYtZm9udC1mYW1pbHkgdi1mb250LXNpemUgdi1mb250LXdlaWdodCB2LWxldHRlci1zcGFjaW5nIiBzdHlsZT0iY29sb3I6IzAwMDAwMDtiYWNrZ3JvdW5kLWNvbG9yOnRyYW5zcGFyZW50O2JvcmRlci1yYWRpdXM6IDQwcHg7bGluZS1oZWlnaHQ6MTIwJTtkaXNwbGF5OmlubGluZS1ibG9jazt0ZXh0LWRlY29yYXRpb246bm9uZTt0ZXh0LWFsaWduOmNlbnRlcjtwYWRkaW5nOjE2cHggNDBweDt3aWR0aDphdXRvO21heC13aWR0aDoxMDAlO3dvcmQtd3JhcDpicmVhay13b3JkO2JvcmRlci1ib3R0b20tY29sb3I6ICMwMDAwMDA7IGJvcmRlci1ib3R0b20tc3R5bGU6IHNvbGlkOyBib3JkZXItYm90dG9tLXdpZHRoOiAxcHg7IGJvcmRlci1sZWZ0LWNvbG9yOiAjMDAwMDAwOyBib3JkZXItbGVmdC1zdHlsZTogc29saWQ7IGJvcmRlci1sZWZ0LXdpZHRoOiAxcHg7IGJvcmRlci1yaWdodC1jb2xvcjogIzAwMDAwMDsgYm9yZGVyLXJpZ2h0LXN0eWxlOiBzb2xpZDsgYm9yZGVyLXJpZ2h0LXdpZHRoOiAxcHg7IGJvcmRlci10b3AtY29sb3I6ICMwMDAwMDA7IGJvcmRlci10b3Atc3R5bGU6IHNvbGlkOyBib3JkZXItdG9wLXdpZHRoOiAxcHg7Zm9udC1zaXplOiAxNHB4OyI+CiAgICB7e01fQU4xWENIc0wudGV4dHx0ZXh0fH19CiAgPC9hPgo8L2Rpdj4KCiAgPC9kaXY+CgogIDwvZGl2Pgo8L2Rpdj4KCiAgICAgIDwvZGl2PgogICAgPC9kaXY+CiAgPC9kaXY+CgogICAgPC9kaXY+CiAgPC9kaXY+CgogIAo8L2Rpdj4KCjwvZGl2PgoKICAgICAgICAgIDxzY3JpcHQgc3JjPSJodHRwczovL2RiazI3anJid243NjEuY2xvdWRmcm9udC5uZXQvcmljaG1lZGlhLXNlcnZpY2Uvc3RhdGlzdGljcy92MS9yaWNobWVkaWEtc3RhdGlzdGljcy5qcz9xPTE3ODIzODEyNTExNDMiPjwvc2NyaXB0PgogICAgICAgIDwvYm9keT4KICAgICAgPC9odG1sPgogICAg"
    private static let pushwooshJSONBase64 = "eyJkZWZhdWx0X2xhbmd1YWdlIjoiZW4iLCJpbnB1dF9ncm91cHMiOltdLCJpb3NfY2xvc2VfYnV0dG9uIjpmYWxzZSwibG9jYWxpemF0aW9uIjp7ImVuIjp7Ik1fQU4xWENIc0wuaHJlZi52YWx1ZXMuaHJlZiI6IiIsIk1fQU4xWENIc0wudGV4dCI6IkdFVCBTVEFSVEVEIiwiTng2c0ZuaTRqVi50ZXh0IjoiXHUwMDNjcCBzdHlsZT1cImxpbmUtaGVpZ2h0OiAxNTAlO1wiXHUwMDNlV2VsY29tZSFcdTAwM2MvcFx1MDAzZVxuXHUwMDNjcCBzdHlsZT1cImxpbmUtaGVpZ2h0OiAxNTAlO1wiXHUwMDNlWW91ciBiZWF1dHkgYm94IGlzIHdhaXRpbmcgZm9yIHlvdSBvbiBHSUZUUyBzY3JlZW4uIENvbWUgdGFrZSBhIGxvb2shwqBcdTAwM2MvcFx1MDAzZSJ9LCJydSI6eyJNX0FOMVhDSHNMLmhyZWYudmFsdWVzLmhyZWYiOiIiLCJNX0FOMVhDSHNMLnRleHQiOiJHRVQgU1RBUlRFRCIsIk54NnNGbmk0alYudGV4dCI6Ilx1MDAzY3Agc3R5bGU9XCJsaW5lLWhlaWdodDogMTUwJTtcIlx1MDAzZVdlbGNvbWUhXHUwMDNjL3BcdTAwM2Vcblx1MDAzY3Agc3R5bGU9XCJsaW5lLWhlaWdodDogMTUwJTtcIlx1MDAzZVlvdXIgYmVhdXR5IGJveCBpcyB3YWl0aW5nIGZvciB5b3Ugb24gR0lGVFMgc2NyZWVuLiBDb21lIHRha2UgYSBsb29rIcKgXHUwMDNjL3BcdTAwM2UifX0sInN0eWxlX3NldHRpbmdzIjp7ImRpc21pc3NfYW5pbWF0aW9uIjoiZG93biIsInBvc2l0aW9uIjoiY2VudGVyIiwicHJlc2VudF9hbmltYXRpb24iOiJub25lIiwic3dpcGVfdG9fZGlzbWlzcyI6WyJsZWZ0IiwicmlnaHQiLCJ1cCIsImRvd24iXX19"
}

// Minimal ZIP writer (stored entries, no compression) - enough for the SDK unarchiver.
enum ZipBuilder {
    static func archive(entries: [(name: String, data: Data)]) -> Data {
        var out = Data()
        var central = Data()
        var count: UInt16 = 0

        for (name, data) in entries {
            let nameBytes = Data(name.utf8)
            let crc = crc32(data)
            let offset = UInt32(out.count)

            out.append(le32(0x04034b50))
            out.append(le16(20)); out.append(le16(0)); out.append(le16(0))
            out.append(le16(0)); out.append(le16(0))
            out.append(le32(crc))
            out.append(le32(UInt32(data.count))); out.append(le32(UInt32(data.count)))
            out.append(le16(UInt16(nameBytes.count))); out.append(le16(0))
            out.append(nameBytes)
            out.append(data)

            central.append(le32(0x02014b50))
            central.append(le16(20)); central.append(le16(20)); central.append(le16(0)); central.append(le16(0))
            central.append(le16(0)); central.append(le16(0))
            central.append(le32(crc))
            central.append(le32(UInt32(data.count))); central.append(le32(UInt32(data.count)))
            central.append(le16(UInt16(nameBytes.count))); central.append(le16(0)); central.append(le16(0))
            central.append(le16(0)); central.append(le16(0))
            central.append(le32(0))
            central.append(le32(offset))
            central.append(nameBytes)
            count += 1
        }

        let centralOffset = UInt32(out.count)
        out.append(central)
        out.append(le32(0x06054b50))
        out.append(le16(0)); out.append(le16(0))
        out.append(le16(count)); out.append(le16(count))
        out.append(le32(UInt32(central.count)))
        out.append(le32(centralOffset))
        out.append(le16(0))
        return out
    }

    private static func le16(_ value: UInt16) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }

    private static func le32(_ value: UInt32) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }

    private static let crcTable: [UInt32] = (0..<256).map { i -> UInt32 in
        var c = UInt32(i)
        for _ in 0..<8 {
            c = (c & 1 == 1) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
        }
        return c
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}
