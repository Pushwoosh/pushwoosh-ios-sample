//
//  NotificationViewController.swift
//  ContentExtension
//
//  Created by André Kis on 04.06.26.
//

import PushwooshNotificationUI

class NotificationViewController: PushwooshStoriesViewController, PushwooshStoriesDelegate {

    override var appGroupIdentifier: String? { "group.com.example.pushstories" }

    override var hapticsEnabled: Bool { true }
    override var longPressToPauseEnabled: Bool { true }
    override var crossfadesBetweenPages: Bool { true }
    override var loopsAfterLastPage: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        storiesDelegate = self
    }

    func storiesViewController(_ controller: PushwooshStoriesViewController, didStartWithPageCount pageCount: Int) {
        print("📖 Stories started — \(pageCount) pages")
    }

    func storiesViewController(_ controller: PushwooshStoriesViewController, didShow page: StoryPage, at index: Int) {
        print("📖 Page \(index) shown — \(page.imageURL.lastPathComponent)")
    }

    func storiesViewController(_ controller: PushwooshStoriesViewController, didTapActionFor page: StoryPage, at index: Int) {
        print("📖 CTA tapped on page \(index) — link: \(page.link?.absoluteString ?? "—")")
    }

    func storiesViewControllerDidFinish(_ controller: PushwooshStoriesViewController) {
        print("📖 Stories finished")
    }

    func storiesViewControllerDidShowFallback(_ controller: PushwooshStoriesViewController) {
        print("📖 Fallback content shown (empty/invalid payload)")
    }
}
