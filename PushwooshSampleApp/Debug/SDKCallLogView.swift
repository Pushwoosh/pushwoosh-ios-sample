//
//  SDKCallLogView.swift
//  PushwooshSampleApp
//

import SwiftUI

struct SDKCallLogView: View {
    @ObservedObject private var logger = SDKCallLogger.shared
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.white)
                    .font(.system(size: 14))

                Text("SDK Call Log (\(logger.callLog.count))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if !logger.callLog.isEmpty {
                    Button(action: {
                        logger.clear()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12))
                    }
                    .padding(.trailing, 8)
                }

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.15, green: 0.15, blue: 0.25)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            // Log content
            if isExpanded {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            if logger.callLog.isEmpty {
                                Text("No SDK calls yet...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            } else {
                                // Header showing total calls
                                Text("📞 SDK Call Stack Trace (\(logger.callLog.count) calls)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 8)
                                    .padding(.top, 8)

                                Divider()
                                    .background(Color.white.opacity(0.3))
                                    .padding(.horizontal, 8)

                                // Show all calls in chronological order
                                ForEach(Array(logger.callLog.enumerated()), id: \.offset) { index, entry in
                                    VStack(alignment: .leading, spacing: 4) {
                                        // Call header with number and method
                                        HStack(alignment: .top, spacing: 4) {
                                            Text("#\(index + 1)")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundColor(.yellow)
                                                .frame(width: 30, alignment: .trailing)

                                            VStack(alignment: .leading, spacing: 2) {
                                                // Method name with timestamp
                                                Text("[\(entry.formattedTimestamp)] \(entry.method)")
                                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.green)

                                                // Parameters
                                                if let params = entry.params, !params.isEmpty {
                                                    Text("→ \(params)")
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .foregroundColor(.cyan)
                                                }

                                                // Result
                                                if let result = entry.result, !result.isEmpty {
                                                    Text("← \(result)")
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .foregroundColor(.orange)
                                                }

                                                // SDK Internal trace
                                                if !entry.callStack.isEmpty {
                                                    Text("📍 SDK Internal Calls:")
                                                        .font(.system(size: 9, weight: .semibold))
                                                        .foregroundColor(.purple)
                                                        .padding(.top, 4)

                                                    ForEach(Array(entry.callStack.enumerated()), id: \.offset) { stackIndex, frame in
                                                        HStack(alignment: .top, spacing: 4) {
                                                            // Arrow showing call flow
                                                            if stackIndex > 0 {
                                                                Text("↓")
                                                                    .font(.system(size: 9, weight: .bold))
                                                                    .foregroundColor(.purple.opacity(0.6))
                                                            } else {
                                                                Text("▶")
                                                                    .font(.system(size: 9))
                                                                    .foregroundColor(.purple)
                                                            }

                                                            // Frame text
                                                            Text(frame)
                                                                .font(.system(size: 9, design: .monospaced))
                                                                .foregroundColor(
                                                                    frame.hasPrefix("🔵") ? .cyan :
                                                                    frame.hasPrefix("✅") ? .green :
                                                                    frame.hasPrefix("❌") ? .red :
                                                                    .white.opacity(0.8)
                                                                )
                                                                .fixedSize(horizontal: false, vertical: true)
                                                        }
                                                        .padding(.leading, CGFloat(min(stackIndex, 3)) * 12)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .id(index)

                                    // Separator between calls
                                    if index < logger.callLog.count - 1 {
                                        Divider()
                                            .background(Color.white.opacity(0.2))
                                            .padding(.horizontal, 8)
                                    }
                                }

                                // Bottom indicator
                                Text("⬆︎ Scroll up to see earlier calls")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .onChange(of: logger.callLog.count) { _ in
                            if let lastIndex = logger.callLog.indices.last {
                                withAnimation {
                                    proxy.scrollTo(lastIndex, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                    .background(Color.black.opacity(0.9))
                }
            }
        }
        .allowsHitTesting(true)
    }
}

#Preview {
    SDKCallLogView()
}
