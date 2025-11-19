//
//  DebugLogsView.swift
//  PushwooshSampleApp
//

import SwiftUI

struct DebugLogsView: View {
    @ObservedObject private var tracer = DebugCallTracer.shared

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.2, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)

            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DEBUG LOGS")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(red: 0.8, green: 0.9, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("SDK Call Stack")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.gray, .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.black)
                                .font(.system(size: 22))
                        )
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Clear button
                if !tracer.calls.isEmpty {
                    HStack {
                        Spacer()
                        Button(action: {
                            tracer.clear()
                        }) {
                            Text("Clear Logs")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [.red.opacity(0.8), .pink.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                        }
                        .padding(.horizontal)
                    }
                }

                // Logs list
                if tracer.calls.isEmpty {
                    Spacer()

                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))

                        Text("No SDK calls yet...")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tracer.calls) { call in
                                CallLogCard(call: call)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
}

struct CallLogCard: View {
    let call: SDKCall

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with method name and timestamp
            HStack {
                Text(call.methodName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text(call.formattedTime)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            // Parameters
            if let params = call.parameters, !params.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Text("→")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)

                    Text(params)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.cyan.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Result
            if let result = call.result, !result.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Text("←")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)

                    Text(result)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.green.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DebugLogsView()
}
