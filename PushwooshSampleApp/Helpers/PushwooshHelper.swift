//
//  PushwooshHelper.swift
//  PushwooshSampleApp
//

import Foundation

class PushwooshHelper {
    static var isUITesting: Bool {
        return ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    static var isDebugMode: Bool {
        return ProcessInfo.processInfo.arguments.contains("DEBUG_SDK_CALLS")
    }

    static func safeCall<T>(_ defaultValue: T, file: String = #file, function: String = #function, line: Int = #line, _ block: () -> T) -> T {
        let methodName = extractMethodName(from: function)
        print("🟢 PushwooshHelper.safeCall called: \(methodName)")
        print("🟢 isDebugMode: \(isDebugMode), isUITesting: \(isUITesting)")

        if isDebugMode {
            print("🟢 Logging call to DebugCallTracer: \(methodName)")
            DebugCallTracer.shared.logCall(methodName, details: "at \(extractFileName(from: file)):\(line)")
        }

        guard !isUITesting else {
            if isDebugMode {
                print("🟢 Logging return (UI Testing mode)")
                DebugCallTracer.shared.logReturn(methodName, value: "⚠️ UI Testing - returning default: \(defaultValue)")
            }
            return defaultValue
        }

        let result = block()

        if isDebugMode {
            DebugCallTracer.shared.logReturn(methodName, value: "\(result)")
        }

        return result
    }

    static func safeCall(file: String = #file, function: String = #function, line: Int = #line, _ block: () -> Void) {
        let methodName = extractMethodName(from: function)

        if isDebugMode {
            DebugCallTracer.shared.logCall(methodName, details: "at \(extractFileName(from: file)):\(line)")
        }

        guard !isUITesting else {
            if isDebugMode {
                DebugCallTracer.shared.logReturn(methodName, value: "⚠️ UI Testing - skipped")
            }
            return
        }

        block()

        if isDebugMode {
            DebugCallTracer.shared.logReturn(methodName, value: "✓ completed")
        }
    }

    // Async version
    static func safeCall(file: String = #file, function: String = #function, line: Int = #line, _ block: () async throws -> Void) async {
        let methodName = extractMethodName(from: function)

        if isDebugMode {
            DebugCallTracer.shared.logCall(methodName, details: "at \(extractFileName(from: file)):\(line)")
        }

        guard !isUITesting else {
            if isDebugMode {
                DebugCallTracer.shared.logReturn(methodName, value: "⚠️ UI Testing - skipped")
            }
            return
        }

        try? await block()

        if isDebugMode {
            DebugCallTracer.shared.logReturn(methodName, value: "✓ completed")
        }
    }

    // Extract clean method name
    private static func extractMethodName(from function: String) -> String {
        // Remove parameter names: "someMethod(param1:param2:)" -> "someMethod()"
        if let openParen = function.firstIndex(of: "(") {
            let methodName = String(function[..<openParen])
            return methodName + "()"
        }
        return function
    }

    // Extract just filename from full path
    private static func extractFileName(from path: String) -> String {
        return (path as NSString).lastPathComponent
    }
}
