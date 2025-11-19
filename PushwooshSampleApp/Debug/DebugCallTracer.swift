//
//  DebugCallTracer.swift
//  PushwooshSampleApp
//

import Foundation
import Combine

struct SDKCall: Identifiable {
    let id = UUID()
    let timestamp: Date
    let methodName: String
    let parameters: String?
    let result: String?

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}

class DebugCallTracer: ObservableObject {
    static let shared = DebugCallTracer()

    @Published var calls: [SDKCall] = []
    @Published var isEnabled = false

    private init() {
        // Check if debug tracing is enabled
        isEnabled = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    func logCall(_ method: String, parameters: String? = nil, result: String? = nil) {
        guard isEnabled else { return }

        let call = SDKCall(
            timestamp: Date(),
            methodName: method,
            parameters: parameters,
            result: result
        )

        DispatchQueue.main.async {
            self.calls.append(call)
        }
        print("🔍 SDK Call: \(method) \(parameters ?? "") -> \(result ?? "")")
    }

    func clear() {
        calls.removeAll()
    }
}
