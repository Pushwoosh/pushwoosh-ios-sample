//
//  Settings.swift
//  newdemo
//
//  Created by Andrew Kis on 12.4.24..
//

import Foundation
import SwiftUI
import PushwooshFramework

struct Settings: View {
    @State private var pushNotificationEnabled = false
    @State private var notificationAlertEnabled = true
    @State private var communicationEnabled = true
    
    private let spacing: CGFloat = 16
    
    var body: some View {
        
        // MARK: - REGISTER FOR PUSH NOTIFICATIONS
        VStack(spacing: 10) {
            HStack {
                Text("REGISTER FOR PUSHES")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                Toggle("", isOn: $pushNotificationEnabled)
                    .padding(.trailing, spacing)
                    .onChange(of: pushNotificationEnabled) { oldValue, newValue in
                        if newValue == true {
                            Pushwoosh.sharedInstance().registerForPushNotifications { token, error in
                                
                            }
                        } else {
                            Pushwoosh.sharedInstance().unregisterForPushNotifications()
                        }
                    }
            }
            .padding()
            
            // MARK: - SHOW ALERT PUSH NOTIFICATIONS
            VStack(spacing: 10) {
                HStack {
                    Text("SHOW ALERT")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    Toggle("", isOn: $notificationAlertEnabled)
                        .padding(.trailing, spacing)
                }
            }
            .padding()
            .frame(height: 50)
            
            // MARK: - SHOW SERVER COMMUNICATION ENABLED
            VStack {
                HStack {
                    Text("COMMUNICATION ENABLED")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Toggle("", isOn: $communicationEnabled)
                        .padding(.trailing, spacing)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding(.top)
    }
}

#Preview {
    Settings()
}
