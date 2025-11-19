//
//  DebugCallTracer.swift
//  PushwooshSampleApp
//

import Foundation
import Combine

class DebugCallTracer: ObservableObject {
    static let shared = DebugCallTracer()

    @Published var calls: [CallEntry] = []
    private let maxCalls = 100
    private var isTracing = false
    private var currentTrace: [String] = []

    struct CallEntry: Identifiable {
        let id = UUID()
        let timestamp: String
        let type: CallType
        let method: String
        let details: String

        enum CallType {
            case call
            case returnValue
            case error
        }

        var color: String {
            switch type {
            case .call: return "🔵"
            case .returnValue: return "✅"
            case .error: return "❌"
            }
        }
    }

    private init() {}

    // MARK: - Tracing Control

    func startTracing() {
        isTracing = true
        currentTrace.removeAll()
        print("🔍 DebugCallTracer: Started tracing")
    }

    func stopTracing() {
        isTracing = false
        print("🔍 DebugCallTracer: Stopped tracing, captured \(currentTrace.count) calls")
    }

    func getCallTrace() -> [String] {
        return currentTrace
    }

    func clearTrace() {
        currentTrace.removeAll()
    }

    func logCall(_ method: String, details: String = "") {
        print("🔵 DebugCallTracer.logCall: \(method) - \(details)")

        if isTracing {
            let traceEntry = "🔵 \(method)\(details.isEmpty ? "" : " | \(details)")"
            currentTrace.append(traceEntry)
        }

        addEntry(.call, method: method, details: details)
        print("🔵 Total calls now: \(calls.count)")
    }

    func logReturn(_ method: String, value: String = "") {
        print("✅ DebugCallTracer.logReturn: \(method) - \(value)")

        if isTracing {
            let traceEntry = "✅ \(method)\(value.isEmpty ? "" : " → \(value)")"
            currentTrace.append(traceEntry)
        }

        addEntry(.returnValue, method: method, details: value)
        print("✅ Total calls now: \(calls.count)")
    }

    func logError(_ method: String, error: String) {
        if isTracing {
            let traceEntry = "❌ \(method) | ERROR: \(error)"
            currentTrace.append(traceEntry)
        }

        addEntry(.error, method: method, details: error)
    }

    private func addEntry(_ type: CallEntry.CallType, method: String, details: String) {
        DispatchQueue.main.async {
            let entry = CallEntry(
                timestamp: self.timestamp(),
                type: type,
                method: method,
                details: details
            )
            self.calls.insert(entry, at: 0)
            if self.calls.count > self.maxCalls {
                self.calls.removeLast()
            }
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.calls.removeAll()
        }
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
