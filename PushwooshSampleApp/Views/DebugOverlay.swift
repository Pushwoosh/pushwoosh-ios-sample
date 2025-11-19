//
//  DebugOverlay.swift
//  PushwooshSampleApp
//

import SwiftUI

struct DebugOverlay: View {
    @ObservedObject var tracer = DebugCallTracer.shared
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text("🔍 SDK Trace")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    tracer.clear()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .font(.system(size: 10))
                }

                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
            }
            .padding(8)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            if isExpanded {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if tracer.calls.isEmpty {
                            Text("No SDK calls yet...")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                                .padding(8)
                        } else {
                            ForEach(tracer.calls) { call in
                                CallRow(call: call)
                            }
                        }
                    }
                }
                .frame(maxHeight: 250)
                .background(Color.black.opacity(0.85))
            }
        }
        .frame(width: 300)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 60)
        .padding(.trailing, 10)
        .allowsHitTesting(true)
    }
}

struct CallRow: View {
    let call: DebugCallTracer.CallEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(call.color)
                    .font(.system(size: 10))

                Text(call.timestamp)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)

                Text(call.method)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(colorForType(call.type))
            }

            if !call.details.isEmpty {
                Text(call.details)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.leading, 20)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            call.type == .error ? Color.red.opacity(0.1) : Color.clear
        )
    }

    private func colorForType(_ type: DebugCallTracer.CallEntry.CallType) -> Color {
        switch type {
        case .call:
            return .cyan
        case .returnValue:
            return .green
        case .error:
            return .red
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        DebugOverlay()
    }
    .onAppear {
        // Preview data
        DebugCallTracer.shared.logCall("registerForPushNotifications()", details: "")
        DebugCallTracer.shared.logReturn("registerForPushNotifications()", value: "success")
        DebugCallTracer.shared.logCall("setTags()", details: "key: test, value: 123")
        DebugCallTracer.shared.logReturn("setTags()", value: "tags saved")
        DebugCallTracer.shared.logCall("getPushToken()", details: "")
        DebugCallTracer.shared.logReturn("getPushToken()", value: "abc123def456...")
    }
}
