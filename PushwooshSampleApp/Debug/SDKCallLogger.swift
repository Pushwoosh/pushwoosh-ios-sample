//
//  SDKCallLogger.swift
//  PushwooshSampleApp
//

import Foundation
import SwiftUI

struct CallStackEntry {
    let timestamp: Date
    let method: String
    let params: String?
    let result: String?
    let callStack: [String]

    var formattedTimestamp: String {
        DateFormatter.localizedString(from: timestamp, dateStyle: .none, timeStyle: .medium)
    }
}

class SDKCallLogger: ObservableObject {
    static let shared = SDKCallLogger()

    @Published var callLog: [CallStackEntry] = []
    private let maxCalls = 50

    private init() {}

    func log(_ method: String, params: String? = nil, result: String? = nil) {
        // Parse result to extract trace if present
        var traceLines: [String] = []
        var actualResult = result

        if let result = result, result.contains("Traced") {
            // Extract trace from result
            let lines = result.split(separator: "\n")
            if lines.count > 1 {
                // First line is "Traced X SDK calls:"
                actualResult = String(lines[0])
                // Rest are the trace lines
                traceLines = lines.dropFirst().map { String($0) }
            }
        }

        let entry = CallStackEntry(
            timestamp: Date(),
            method: method,
            params: params,
            result: actualResult,
            callStack: traceLines
        )

        DispatchQueue.main.async {
            self.callLog.append(entry)

            // Keep only last maxCalls entries
            if self.callLog.count > self.maxCalls {
                self.callLog.removeFirst(self.callLog.count - self.maxCalls)
            }
        }

        // Print to console
        print("🔍 SDK Call: [\(entry.formattedTimestamp)] \(method)")
        if let params = params {
            print("   → \(params)")
        }
        if let result = result {
            print("   ← \(result)")
        }
        print("   📍 Call Stack:")
        for (index, frame) in entry.callStack.enumerated() {
            print("      \(index + 1). \(frame)")
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.callLog.removeAll()
        }
    }
}
