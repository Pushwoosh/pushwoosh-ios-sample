# PushMart sample — what triggers which Pushwoosh SDK call

This maps every user-facing action in the sample to the public Pushwoosh SDK call it
makes under the hood, and where that lives in code. Use it to demo a feature or to find
the integration point for a given SDK method.

> Keep this in sync: **whenever the sample changes (a screen, an action, an SDK call),
> update this file in the same change.**

Two SDK surfaces are used:
- `Pushwoosh.configure.*` — the modern sanctioned API (most calls).
- Standalone managers: `PWInAppManager` (events + JS bridge), `PWInbox` (inbox data), `Pushwoosh.media` (rich media), `Pushwoosh.LiveActivities`, `Pushwoosh.debug`, `Pushwoosh.ForegroundPush` (in-app foreground banner), `Pushwoosh.VoIP` (CallKit), `PushwooshInboxKit` (inbox UI).

Most SDK calls route through `PushwooshHelper.safeCall { … }`, which skips the call under the `UI_TESTING` launch arg.

---

## App boot — `PushwooshSampleApp.swift` (AppDelegate)

| What happens | SDK call |
|---|---|
| Launch | `Pushwoosh.configure.delegate = self` (PWMessagingDelegate) |
| Launch | `Pushwoosh.configure.purchaseDelegate = self` (PWPurchaseDelegate) + `PurchaseTracker` (SKPaymentTransactionObserver) → `Pushwoosh.configure.sendSKPaymentTransactions(_:)` |
| Rich-media in-app purchase | `PWPurchaseDelegate.onPWInAppPurchaseHelperPaymentComplete/…Failed…/…Products/…Promoted/…RestoreFailed` |
| Launch | `Pushwoosh.LiveActivities.setup(LiveActivityDemoAttributes/LiveScoreAttributes/RadioBroadcastAttributes/ElectionAttributes)` |
| Launch | `Pushwoosh.LiveActivities.defaultSetup()` — registers the SDK-bundled `DefaultLiveActivityAttributes` for push-to-start |
| Launch | `Pushwoosh.media.setRichMediaPresentationStyle(.modal)` + `modalRichMedia.configure(…)` + `PWRichMediaManager.shared().delegate = self` / `Pushwoosh.media.modalRichMedia.setDelegate(self)`+`getDelegate()` (PWRichMediaPresentingDelegate: shouldPresent/didPresent/didClose/presentingDidFail) |
| Reminders → "Enable notifications" button | Push Primer: `Pushwoosh.configure.pushPrimer.style/position/title/message/acceptButton/declineButton/backgroundColor/backgroundGradient/titleColor/messageColor/acceptButtonColor/acceptButtonTextColor/declineButtonColor/declineButtonTextColor/cornerRadius/buttonCornerRadius/buttonBorderColor/fallbackToSettings/minInterval/image.present { }` — presented on demand via `AppDelegate.showPushPrimer()`, not at launch |
| Launched from a push tap | `Pushwoosh.configure.launchNotification()` → `DeepLinkRouter.route(…)` |
| APNs token / failure | `Pushwoosh.configure.handlePushRegistration(_:)` / `handlePushRegistrationFailure(_:)` |
| Push received / opened | `PWMessagingDelegate.pushwoosh(_:onMessageReceived/Opened:)` → `Pushwoosh.configure.getCustomPushData(message.payload)` + `DeepLinkRouter.route(message.customData)` |
| Launch | `Pushwoosh.ForegroundPush` appearance (backgroundColor/titlePushColor/messagePushColor/usePushAnimation/useLiquidView) + `foregroundNotificationWith(style:duration:vibration:disappearedPushAnimation:)` + `didTapForegroundPush` |
| Launch | `VoIPController.start()` → `Pushwoosh.VoIP.delegate = self` + `Pushwoosh.VoIP.initializeVoIP(_:ringtoneSound:handleTypes:)` + `Pushwoosh.VoIP.setIncomingCallTimeout(_:)`. SDK owns the PKPushRegistry + VoIP token registration; `setVoIPToken` not used. Full call UI + delegate coverage on the VoIP calls screen (see below) |
| Launch | `PWInAppManager.shared().addJavascriptInterface(PushMartJSBridge, withName: "PushMart")` (native object callable from rich-media HTML) |
| Deep-link URL opened (`.onOpenURL`) | `Pushwoosh.configure.handleOpenURL(url)` (test-device registration) + carousel demo routing |
| Manual UN-delegate forwarding (E2E-gated) | `Pushwoosh.configure.addNotificationCenterDelegate(_:)` + `handleWillPresentNotification(_:completionHandler:)` + `handleNotificationResponse(_:completionHandler:)` + `handlePushReceived(_:)` (for hosts not using swizzling) |
| Server routing | `Pushwoosh.configure.setReverseProxy(_:headers:)` (reads `PushMartStore.appCode`) — `ServerRouting.apply()` |

## Support — PushMart Care — `Views/SupportView.swift` (+ `Helpers/VoIPController.swift`)

The Support tab. A branded care line: the shopper voice- or video-calls a specialist,
requests a callback, or simulates an incoming call (in-app or over the lock screen while
backgrounded). Outgoing calls are real CallKit calls; the SDK owns the CXProvider/
CXCallController and hands them to the app via the delegate — the app never creates its
own provider. The live "presence ring" around the specialist changes colour and rhythm
with the call state. Config + the raw delegate event log sit behind an "SDK & call log"
disclosure.

| User action | SDK call |
|---|---|
| Open screen (capture CallKit handles) | `PWVoIPCallDelegate.returnedCallController(_:)` + `returnedProvider(_:)` — the SDK hands the app its CXCallController + CXProvider; the app also sets a `CXCallObserver` delegate |
| Token status | `voipDidRegisterTokenSuccessfully()` / `voipDidFailToRegisterToken(error:)` |
| Voice call / Video call | `callController.request(CXTransaction(CXStartCallAction(call:handle:)))` (isVideo set for video) → SDK `provider(_:perform: CXStartCallAction)` → `startCall(_:perform:)` → `provider.reportOutgoingCall(with:startedConnectingAt:)` then `connectedAt:` |
| Call me back | `PWInAppManager.shared().postEvent("request_callback", withAttributes: ["channel": "support"])` — signals the backend to place a VoIP call back to the user; the demo then rings a simulated incoming call |
| End call (in-app button) | `provider.reportCall(with:endedAt:reason: .remoteEnded)` (app-initiated calls aren't in the SDK's push map, so `CXEndCallAction` is not used for them) |
| End call from the native CallKit screen | Caught by `CXCallObserver.callObserver(_:callChanged:)` (`call.hasEnded`) — the SDK provider's `CXEndCallAction` fails for app-initiated calls, so the observer is what resets the app state |
| Mute / Hold | `callController.request(CXSetMutedCallAction(call:muted:))` / `CXSetHeldCallAction(call:onHold:)` → SDK `mutedCall(_:perform:)` / `heldCall(_:perform:)` |
| Simulate incoming call (dev) → Answer / Decline | In-app only: synthesizes the `.incoming` state locally (no server round-trip), then Answer/Decline drive the same UI |
| Ring me in the background (dev) | `provider.reportNewIncomingCall(with:update:)` on a delay — CallKit rings over the lock screen even while the app is backgrounded, like a real VoIP push. Local demo: answering won't connect (no push payload); decline/end are caught by `CXCallObserver` |
| Incoming call (server VoIP push) | `voipDidReceiveIncomingCall(payload:)` + `voipDidReportIncomingCallSuccessfully(voipMessage:)` / `voipDidFailToReportIncomingCall(error:)`; answer/end via `answerCall(_:perform:voipMessage:)` / `endCall(_:perform:voipMessage:)` |
| Cancelled call | `voipDidCancelCall(voipMessage:)` / `voipDidFailToCancelCall(callId:reason:)` |
| Provider / audio lifecycle | `pwProviderDidBegin(_:)` / `pwProviderDidReset(_:)` / `activatedAudioSession(_:didActivate:)` / `deactivatedAudioSession(_:didDeactivate:)` / `playDTMF(_:perform:)` |
| Popular topic tapped | `PWInAppManager.shared().postEvent("support_*", withAttributes: ["channel": "support"])` |
| Apply configuration | `Pushwoosh.VoIP.initializeVoIP(_:ringtoneSound:handleTypes:)` + `setIncomingCallTimeout(_:)` + `setRingtone(_:)` |

Note: like the Android and Cordova samples, calls normally originate from a server VoIP push; the in-app Voice/Video call and the simulated/background incoming calls are iOS-only demos made possible because the SDK exposes its CXCallController/CXProvider. A fully answerable backgrounded incoming call still requires a real server VoIP push.

## Onboarding — `Onboarding/OnboardingFlow.swift`

| User action | SDK call |
|---|---|
| Connect → enter store code → Continue | `Pushwoosh.configure.setAppCode(code)` + `ServerRouting.apply()` |
| Sign in → Continue | `Pushwoosh.configure.setEmail(email)` + `Pushwoosh.configure.setUserId(email)` |

## Home tab — `Views/RootTabView.swift` (HomeTabView)

| User action | SDK call |
|---|---|
| Tap a deal card (Flash sale / Members / Bundle) | `PWInAppManager.shared().postEvent("showRichMedia" / "showRichMediaClient" / "showRichMediaServer")` |
| Tap hero "Shop the drop" | presents `SaleView` (deep-link destination `pushwoosh://sale`) |

## Shop tab & product detail — `Views/RootTabView.swift`

| User action | SDK call |
|---|---|
| Open a product | `PWInAppManager.shared().postEvent("product-opened", ["productId": id])` |
| Add to bag | `CartStore.add` → `PWInAppManager.postEvent("add-to-cart", …)` + `Pushwoosh.configure.sendBadges(cartCount)` |
| Cart count changes | `Pushwoosh.configure.sendBadges(cartCount)` (app icon badge) |

## Cart & checkout — `Views/CartView.swift`

| User action | SDK call |
|---|---|
| Checkout (per item) | `Pushwoosh.configure.sendPurchase(id, withPrice:currencyCode:andDate:)` |
| Checkout (tags) | `Pushwoosh.configure.setTags(["orders_placed": PWTagsBuilder.incrementalTag(with:1), "purchased_products": PWTagsBuilder.appendValues(toListTag: ids)])` |
| Checkout (event) | `PWInAppManager.shared().postEvent("checkout", ["items":…, "total":…])` |
| Checkout (live activity) | `ManualLiveActivityController.startOrder(id:)` → `Activity<LiveActivityDemoAttributes>.request(pushType:.token)` → `Pushwoosh.LiveActivities.startLiveActivity(token:activityId:)` |
| Checkout clears cart | `Pushwoosh.configure.sendBadges(0)` |

## Orders tab (Live Activities) — `Views/LiveActivitiesView.swift`

| User action | SDK call |
|---|---|
| Start live tracking | `Activity.request(pushType:.token)` → observe `pushTokenUpdates` → `Pushwoosh.LiveActivities.startLiveActivity(token:activityId:)` |
| Stop tracking | `activity.end(…)` + `Pushwoosh.LiveActivities.stopLiveActivity(activityId:)` |
| Enable remote start (iOS 17.2+) | observe `Activity.pushToStartTokenUpdates` → `Pushwoosh.LiveActivities.sendPushToStartLiveActivity(token:)` |
| Flash-sale drops → Remind me / cancel | `Pushwoosh.LiveActivities.schedule(attributes:contentState:at:…)` / `cancel(LiveScoreAttributes.self, activityId:)` |
| Restock reminders → Notify me / cancel | `Pushwoosh.LiveActivities.schedule(…)` / `cancel(RadioBroadcastAttributes.self, activityId:)` |
| Election night (local demo) | `Activity<ElectionAttributes>.request(pushType: nil)` → `activity.update(…)` per counting round → `activity.end(…)`; local ActivityKit only, no Pushwoosh push transport |
| Start default activity | `Pushwoosh.LiveActivities.defaultStart(id, attributes:, content:) { error in }` — bundled `DefaultLiveActivityAttributes`, no custom struct needed (an iOS 26 scheduled `defaultStart(…at:alertTitle:alertBody:)` overload also exists) |
| Stop default activity | `Pushwoosh.LiveActivities.stopLiveActivity(activityId:)` |
| Launch StoryReel | one `Activity<StoryReelAttributes>.request(…, pushType:nil)` PER story (2) → iOS groups the cards on the Lock Screen under the app (the StoryReel look); local ActivityKit demo, no Pushwoosh call. Stop ends all. Covers are bundled images in the widget asset catalog |

## Inbox tab — Default / Custom chooser — `Views/InboxKitView.swift`

| User action | SDK call |
|---|---|
| Open Inbox tab | Two-row chooser (Default / Custom); each row pushes `InboxDetailView(styled:)` full-screen |
| Default offers row | `PushwooshInboxKitViewController(attributes:)` with the SDK's built-in cells |
| Custom offers row | `attributes.cells["captioned"] = PromoCaptionedCell.self` (host cell + brand appearance) |
| Appearance (on create) | `vc.setBackgroundColor/setAccentColor/setSeparatorColor/setEmptyMessage/setEmptyImage/setErrorMessage/setErrorImage/setDateFormatter/setSwipeToDeleteEnabled/setEnableDarkTheme/setPinningEnabled/setPinIndicatorVisible/setPinIndicatorColor/setInlineButtonsEnabled/setButtonBackgroundColor/setButtonTextColor/setButtonFont` + reads `vc.attributes` |
| Nav-bar ⋯ → Mark all read | `PushwooshInboxKitViewController.markAllAsRead` |
| Nav-bar ⋯ → Delete all | `PushwooshInboxKitViewController.deleteAllMessages` |
| Nav-bar ⋯ → Reload / Reload (async) / Clear read | `vc.reloadData()` / `try await vc.reload()` / `vc.clearReadMessages()` |
| Tap a message | `vc.markRead(messages:)` (via `PushwooshInboxKitDelegate`) |
| Unread tab badge + chooser "N new" pill | `PWInbox.unreadMessagesCount { }` + `PWInbox.addObserverForUnreadMessagesCount { }` — `InboxUnreadModel` |
| Delegate callbacks | `inboxKit(_:willDisplay:at:)`, `inboxKit(_:didSelect:)→Bool`, `inboxKit(_:shouldDelete:)→Bool`, `inboxKit(_:didRefreshWith:error:)`, `inboxKit(didDismiss:)`, `inboxKit(_:didTapButton:onMessage:)→Bool` |
| Add to Wallet | delegate `inboxKit(_:didAddWalletPassFor:)` / `inboxKit(_:didFailToAddWalletPassFor:error:)` |

## Account — `Views/UserView.swift`

| User action | SDK call |
|---|---|
| Save changes | `Pushwoosh.configure.setUserId(id)` + `Pushwoosh.configure.setEmail(email)` |
| Tap card / Sync | `Pushwoosh.configure.getUserId()` |
| Register all emails | `Pushwoosh.configure.setEmails(list) { error in }` |
| Link ID + these emails | `Pushwoosh.configure.setUser(id, emails: list) { error in }` |
| Merge into current member | `Pushwoosh.configure.mergeUserId(oldId, to: currentId, doMerge:) { error in }` |
| Text me updates (SMS) | `Pushwoosh.configure.registerSmsNumber(number)` |
| WhatsApp updates | `Pushwoosh.configure.registerWhatsappNumber(number)` |

## Push notifications — `Views/RegistrationView.swift`

| User action | SDK call |
|---|---|
| Toggle on / Turn on | `Pushwoosh.configure.registerForPushNotifications()` |
| Toggle off | `Pushwoosh.configure.unregisterForPushNotifications(_:)` |
| Check status / Delivery details | `Pushwoosh.sharedInstance().getPushToken()` + `Pushwoosh.configure.getHWID()` + `Pushwoosh.configure.getRemoteNotificationStatus()` + `UNUserNotificationCenter.notificationSettings()` |
| Re-register this device | `Pushwoosh.configure.registerForPushNotifications { token, error in }` (completion variant → token/error) |
| Clear delivered pushes | `Pushwoosh.configure.clearNotificationCenter()` |
| Ask quietly (provisional) toggle | `Pushwoosh.configure.setAdditionalAuthorizationOptions(_:)` (+ `getAdditionalAuthorizationOptions()` on appear) |
| Preview foreground banner | `Pushwoosh.ForegroundPush.showForegroundPush(userInfo:)` |

## Reminders (Alerts) — `Views/NotificationsView.swift`

| User action | SDK call |
|---|---|
| Remind me about … in … | `Notifications.shared.showLocalNotification(title:body:delay:)` (UserNotifications, not Pushwoosh) |
| Clear reminders | `PushNotificationManager.clearNotificationCenter()` |

## Preferences — `Views/TagsView.swift`

| User action | SDK call |
|---|---|
| Follow a category chip | `Pushwoosh.configure.setTags(["fav_<category>": "true"/"false"])` |
| Save a custom preference | `Pushwoosh.configure.setTags([key: value]) { error in }` (completion variant) |
| Follow / Unfollow a brand | `Pushwoosh.configure.setTags(["followed_brands": PWTagsBuilder.appendValues(toListTag:) / removeValues(fromListTag:)])` |
| Save email preference | `Pushwoosh.configure.setEmailTags([key: value], forEmail: email) { error in }` |
| Load "Your preferences" | `Pushwoosh.configure.loadTags(_:error:)` |

## App settings — `Views/SettingsView.swift`

| User action | SDK call |
|---|---|
| Show alerts toggle | `Pushwoosh.configure.setShowPushnotificationAlert(_:)` (+ `getShowPushnotificationAlert()` on appear) |
| Set language / Current | `Pushwoosh.configure.setLanguage(_:)` / `getLanguage()` |
| Set access code | `Pushwoosh.configure.setAppCode(_:)` |
| Set API token / Current | `Pushwoosh.configure.setApiToken(_:)` / `getApiToken()` |

## Data & sync — `Views/CommunicationView.swift`

| User action | SDK call |
|---|---|
| Pause / Resume sync | `Pushwoosh.configure.stopServerCommunication()` / `startServerCommunication()` |
| Check status | `Pushwoosh.configure.isServerCommunicationAllowed()` |

## Device — `Views/DeviceInfoView.swift`

| User action | SDK call |
|---|---|
| Passport / Refresh | `Pushwoosh.configure.getPushToken()` + `getHWID()` + `getApplicationCode()` |

## Inbox data — `Views/InboxDataView.swift`

| User action | SDK call |
|---|---|
| Open screen / Refresh counts | `PWInbox.messagesCount { }` + `PWInbox.unreadMessagesCount { }` + `PWInbox.messagesWithNoActionPerformedCount { }` |
| Load / Reload messages | `PWInbox.loadMessages { }` |
| Tap a message | `PWInbox.performAction(forMessageWithCode:)` + `PWInbox.readMessages(withCodes:)` + `PWInbox.message(forCode:)` |
| Delete a message (trash) | `PWInbox.deleteMessages(withCodes:)` |
| Mark all read | `PWInbox.markAllMessagesAsRead()` |
| Delete read | `PWInbox.deleteAllReadMessages()` |
| Resync for user | `PWInbox.resyncInboxForNewUserId()` (async wrapper over `updateInboxForNewUserId:`) |
| Open screen (subscribe) | `PWInbox.addObserverForDidReceiveInPushNotification { }` + `addObserverForUpdateInboxMessages { }` + `addObserverForUnreadMessagesCount { }` + `addObserverForNoActionPerformedMessagesCount { }` |
| Leave screen (unsubscribe) | `PWInbox.removeObserver(_:)` (per kept token) |

## Rich media appearance — `Views/MediaView.swift`

| User action | SDK call |
|---|---|
| Apply settings | `Pushwoosh.media.setRichMediaPresentationStyle(_:)` + `Pushwoosh.media.richMediaPresentationStyle()` (read-back) + `modalRichMedia.configure/setAnimationDuration/setDismissSwipeDirections/setHapticFeedbackType/setCornerType/close(after:)` + `PWRichMediaManager.shared().richMediaStyle = PWRichMediaStyle()` (backgroundColor/closeButtonPresentingDelay/shouldHideStatusBar/allowsInlineMediaPlayback/mediaPlaybackRequiresUserAction) |
| Mock rich-media buttons | `PWInAppManager.shared().postEvent("showRichMedia…")` (via local mock server, `PWMockServerEnabled`) |
| Native in-app (split) button | `PWInAppManager.shared().postEvent("showNativeInApp")` — mock serves a ZIP carrying `native-config.json`; the SDK splitter routes it to the native PushwooshInApp module instead of HTML rich media |

## Push custom-data deep links — `Helpers/DeepLinkRouter.swift`

| Push custom data (`u`) | Result |
|---|---|
| `{ "product_id": "<id>" }` | opens that product (`PushMartProductDetail`) |
| `{ "voucher": "<code>" }` | shows `VoucherView` |
| `{ "sale": true }` | opens `SaleView` |

## Developer (DEBUG only) — `Views/DeveloperView.swift`

| User action | SDK call |
|---|---|
| Log level chip | `Pushwoosh.debug.setLogLevel(.PW_LL_*)` |
| Reload in-app resources | `PWInAppManager.shared().reloadInApps { }` |
| SDK version row | `Pushwoosh.configure.version()` |
