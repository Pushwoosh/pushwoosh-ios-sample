//
//  MenuCategory.swift
//  PushwooshSampleApp
//

import SwiftUI

enum MenuCategory: String, CaseIterable, Identifiable {
    case user = "User"
    case registration = "Registration"
    case tags = "Tags"
    case device = "Device Info"
    case communication = "Communication"
    case settings = "Settings"
    case monetization = "Monetization"
    case liveActivities = "Live Activities"
    case notifications = "Notifications"
    // case debugLogs = "Debug Logs"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .user: return "person.fill"
        case .registration: return "bell.badge.fill"
        case .tags: return "tag.fill"
        case .device: return "iphone"
        case .communication: return "antenna.radiowaves.left.and.right"
        case .settings: return "gearshape.fill"
        case .monetization: return "dollarsign.circle.fill"
        case .liveActivities: return "livephoto"
        case .notifications: return "app.badge.fill"
        // case .debugLogs: return "list.bullet.rectangle"
        }
    }

    var color: Color {
        switch self {
        case .user: return .blue
        case .registration: return .purple
        case .tags: return .pink
        case .device: return .cyan
        case .communication: return .green
        case .settings: return .orange
        case .monetization: return .yellow
        case .liveActivities: return .indigo
        case .notifications: return .red
        // case .debugLogs: return .gray
        }
    }
}
