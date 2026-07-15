//
//  PushwooshHelper.swift
//  PushwooshSampleApp
//

import Foundation
import SwiftUI
import UIKit

extension View {
    func dismissKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

// Thin guard around SDK calls: under UI_TESTING the call is skipped and the
// default is returned, so the automated suite never hits the live SDK.
class PushwooshHelper {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    static func safeCall<T>(_ defaultValue: T, _ block: () -> T) -> T {
        guard !isUITesting else { return defaultValue }
        return block()
    }

    static func safeCall(_ block: () -> Void) {
        guard !isUITesting else { return }
        block()
    }

    static func safeCall(_ block: () async throws -> Void) async {
        guard !isUITesting else { return }
        try? await block()
    }
}
