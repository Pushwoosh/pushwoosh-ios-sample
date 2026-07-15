//
//  TagsView.swift
//  PushMart
//

import SwiftUI
import PushwooshFramework

// Preferences screen. Signature: tappable favorite-category chips — each toggle
// writes a device tag. A custom key/value setter and an inline "current tags"
// readout (loadTags) round it out. setTags fires the shared success overlay.
struct TagsView: View {
    @State private var favorites: Set<String> = []
    @State private var tagKey = ""
    @State private var tagValue = ""
    @State private var loadedTags: [AnyHashable: Any] = [:]
    @State private var loadedOnce = false
    @State private var brand = ""
    @State private var emailForTags = ""
    @State private var emailTagKey = ""
    @State private var emailTagValue = ""

    private let categories = ["Sneakers", "Audio", "Watches", "Bags", "Tech"]

    var body: some View {
        ZStack {
            PushMartBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    favoritesCard
                        .sdkNote("Pushwoosh.configure.setTags(_:)",
                                 "Each category chip toggles a device tag so campaigns can target people by the categories they follow.",
                                 calls: [
                                    .init(code: "setTags([\"fav_sneakers\": \"true\"])",
                                          note: "Following a category writes its tag as \"true\"."),
                                    .init(code: "setTags([\"fav_sneakers\": \"false\"])",
                                          note: "Unfollowing writes the same tag as \"false\"."),
                                 ])
                    customCard
                    listTagCard
                    emailTagsCard
                    currentCard
                        .sdkNote("Pushwoosh.configure.loadTags(_:error:)",
                                 "Loads the tags currently stored for this device and lists them inline.",
                                 calls: [
                                    .init(code: "loadTags({ tags in }, error: { error in })",
                                          note: "The success closure receives the current tag dictionary; the error closure reports failures."),
                                 ])
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Preferences").font(PushMart.display(32)).foregroundStyle(PushMart.textPrimary)
            Text("Tell us what you love").font(PushMart.body(14)).foregroundStyle(PushMart.textSecondary)
        }
        .padding(.top, 4)
    }

    // MARK: Signature — favorite chips

    private var favoritesCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Shop the categories you love").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                FlowChips(items: categories, selected: favorites) { toggle($0) }
                Text("Tap to follow a category — we'll tune your deals and drops to match.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func toggle(_ category: String) {
        let on: Bool
        if favorites.contains(category) { favorites.remove(category); on = false }
        else { favorites.insert(category); on = true }
        let key = "fav_\(category.lowercased())"
        Pushwoosh.configure.setTags([key: on ? "true" : "false"])
        PushMartResult.shared.success(on ? "Following \(category)" : "Unfollowed \(category)",
                                      on ? "You'll see more \(category) deals." : "Removed from your favorites.")
    }

    // MARK: Custom preference

    private var customCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Add a custom preference").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                PushMartField(placeholder: "PREFERENCE", text: $tagKey, icon: "tag.fill")
                PushMartField(placeholder: "VALUE", text: $tagValue, icon: "textformat")
                PushMartButton(title: "Save", icon: "checkmark") {
                    let key = tagKey.trimmingCharacters(in: .whitespaces)
                    guard !key.isEmpty else {
                        PushMartResult.shared.fail("Nothing to save", "Enter a preference name first.")
                        return
                    }
                    PushwooshHelper.safeCall {
                        Pushwoosh.configure.setTags([tagKey: tagValue]) { error in
                            DispatchQueue.main.async {
                                if let error { PushMartResult.shared.fail("Save failed", error.localizedDescription) }
                                else { PushMartResult.shared.success("Preference saved", "\(tagKey): \(tagValue)") }
                            }
                        }
                    }
                }
                .sdkNote("Pushwoosh.configure.setTags(_:completion:)",
                         "Saves a custom key/value device tag and reports success or failure through the completion handler.",
                         calls: [
                            .init(code: "setTags([tagKey: tagValue]) { error in }",
                                  note: "Writes your custom preference; the completion returns an NSError, or nil on success."),
                         ])
            }
        }
    }

    // MARK: Followed brands — list tag (append / remove values)

    private var listTagCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Followed brands").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                PushMartField(placeholder: "BRAND", text: $brand, icon: "star.fill")
                HStack(spacing: 10) {
                    PushMartButton(title: "Follow", icon: "plus", style: .secondary) { changeBrand(follow: true) }
                    PushMartButton(title: "Unfollow", icon: "minus", style: .secondary) { changeBrand(follow: false) }
                }
                .sdkNote("Pushwoosh.configure.setTags(_:)",
                         "Follows or unfollows a brand by adding or removing a value in the `followed_brands` list tag via PWTagsBuilder.",
                         calls: [
                            .init(code: "setTags([\"followed_brands\": PWTagsBuilder.appendValues(toListTag: [brand])])",
                                  note: "Follow - appends the brand to the list tag, leaving existing values untouched."),
                            .init(code: "setTags([\"followed_brands\": PWTagsBuilder.removeValues(fromListTag: [brand])])",
                                  note: "Unfollow - removes just that brand from the list tag."),
                         ])
                Text("Adds or removes a value from the `followed_brands` list tag with PWTagsBuilder.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func changeBrand(follow: Bool) {
        let value = brand.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { PushMartResult.shared.fail("No brand", "Enter a brand name first."); return }
        let op = follow ? PWTagsBuilder.appendValues(toListTag: [value])
                        : PWTagsBuilder.removeValues(fromListTag: [value])
        Pushwoosh.configure.setTags(["followed_brands": op])
        PushMartResult.shared.success(follow ? "Following \(value)" : "Unfollowed \(value)",
                                      follow ? "Added to your brand list." : "Removed from your brand list.")
    }

    // MARK: Email-scoped tags (setEmailTags:forEmail:)

    private var emailTagsCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Email preferences").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                PushMartField(placeholder: "EMAIL", text: $emailForTags, icon: "envelope.fill")
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                PushMartField(placeholder: "PREFERENCE", text: $emailTagKey, icon: "tag.fill")
                PushMartField(placeholder: "VALUE", text: $emailTagValue, icon: "textformat")
                PushMartButton(title: "Save email preference", icon: "checkmark", style: .secondary) {
                    let mail = emailForTags.trimmingCharacters(in: .whitespaces)
                    let key = emailTagKey.trimmingCharacters(in: .whitespaces)
                    guard !mail.isEmpty, !key.isEmpty else {
                        PushMartResult.shared.fail("Missing input", "Need an email and a preference name.")
                        return
                    }
                    PushwooshHelper.safeCall {
                        Pushwoosh.configure.setEmailTags([key: emailTagValue], forEmail: mail) { error in
                            DispatchQueue.main.async {
                                if let error { PushMartResult.shared.fail("Email tag failed", error.localizedDescription) }
                                else { PushMartResult.shared.success("Email preference saved", "\(mail) · \(key): \(emailTagValue)") }
                            }
                        }
                    }
                }
                .sdkNote("Pushwoosh.configure.setEmailTags(_:forEmail:completion:)",
                         "Sets tags on an email profile (requires the Email channel), kept separate from device tags.",
                         calls: [
                            .init(code: "setEmailTags([key: value], forEmail: email) { error in }",
                                  note: "Writes the preference onto the given email profile; the completion returns an NSError, or nil on success."),
                         ])
                Text("Tags set on an email profile (requires the Email channel), separate from device tags.")
                    .font(PushMart.body(12.5)).foregroundStyle(PushMart.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Current tags (loadTags, inline)

    private var currentCard: some View {
        PushMartCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Your preferences").font(PushMart.headline(17)).foregroundStyle(PushMart.textPrimary)
                    Spacer()
                    Button { loadCurrent() } label: {
                        Text(loadedOnce ? "Refresh" : "Load").font(PushMart.label(13)).foregroundStyle(PushMart.coral)
                    }
                }
                if loadedOnce {
                    if sortedTags.isEmpty {
                        Text("No preferences saved yet.").font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                    } else {
                        ForEach(sortedTags, id: \.0) { pair in
                            HStack {
                                Text(pair.0).font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                                Spacer()
                                Text(pair.1).font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(PushMart.textPrimary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } else {
                    Text("Load the tags currently stored for this device.")
                        .font(PushMart.body(13)).foregroundStyle(PushMart.textSecondary)
                }
            }
        }
    }

    private var sortedTags: [(String, String)] {
        loadedTags.map { ("\($0.key)", "\($0.value)") }.sorted { $0.0 < $1.0 }
    }

    private func loadCurrent() {
        Pushwoosh.configure.loadTags(
            { tags in
                loadedTags = tags ?? [:]
                loadedOnce = true
            },
            error: { error in
                loadedTags = [:]
                loadedOnce = true
                PushMartResult.shared.fail("Couldn't load", error?.localizedDescription ?? "Unknown error")
            }
        )
    }
}

// Simple wrapping chip row.
struct FlowChips: View {
    let items: [String]
    let selected: Set<String>
    let onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button { onTap(item) } label: {
                    PushMartChip(title: item, selected: selected.contains(item),
                                 icon: selected.contains(item) ? "checkmark" : nil)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    TagsView()
}
