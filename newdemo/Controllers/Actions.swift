//
//  Actions.swift
//  newdemo
//
//  Created by Andrew Kis on 12.4.24..
//

import Foundation
import SwiftUI
import PushwooshFramework

struct Actions: View {
    @State private var textInputKey: String = ""
    @State private var textInputValue: String = ""
    @State private var textInputUser: String = ""
    @State private var textInputEventName: String = ""
    @State private var attributesEnabled = false
    @State private var alertEnabled = true
    @State private var textInputEmail: String = ""
    @State private var textInputLanguage: String = ""
    @State private var showAlert = false
    @State private var showAlertAppCode = false
    @State private var showPushToken = false
    @State private var showHwid = false
    @State private var showUserId = false

    var body: some View {
        let pushToken = Pushwoosh.sharedInstance().getPushToken()
        let hwid = Pushwoosh.sharedInstance().getHWID()
        let userId = Pushwoosh.sharedInstance().getUserId()
        
        ScrollView {
            VStack(spacing: 15) {
                HStack {
                    Text("PUSHWOOSH DEMO")
                        .font(.system(size: 20, weight: .bold))
                        .frame(height: 50)
                    Spacer()
                    
                }
                
                // MARK: - SET TAGS
                HStack {
                    ActionButton(title: "SET TAGS") {
                        Pushwoosh.sharedInstance().setTags([textInputKey: textInputValue])
                        showAlert = true
                    }
                    .alert(isPresented: $showAlert, content: {
                        alert(title: "SET TAGS", 
                              message: "TAGS: key = \(textInputKey), value = \(textInputValue)")
                    })
                    
                    Spacer()
                    
                    TextField("KEY", text: $textInputKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Spacer()
                    
                    TextField("VALUE", text: $textInputValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // MARK: - REGISTER USER
                HStack {
                    ActionButton(title: "REGISTER USER") {
                        Pushwoosh.sharedInstance().setUserId(textInputUser)
                    }
                    
                    Spacer()
                    
                    TextField("USER", text: $textInputUser)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // MARK: - POST EVENT
                HStack {
                    ActionButton(title: "POST EVENT") {
                        if attributesEnabled  {
                            PWInAppManager.shared().postEvent(textInputEventName, withAttributes: ["Key1": "Value1", "Key2": "Value2"])
                        } else {
                            PWInAppManager.shared().postEvent(textInputEventName)
                        }
                    }
                    
                    Spacer()
                    
                    TextField("EVENT NAME", text: $textInputUser)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // MARK: - Attributes
                HStack {
                    Spacer()
                    Text("WITH ATTRIBUTES ENABLED")
                        .font(.system(size: 14))
                    Spacer()
                    
                    Toggle("", isOn: $attributesEnabled)
                        .onChange(of: attributesEnabled) { oldValue, newValue in
                            attributesEnabled = newValue
                        }
                }
                
                // MARK: - REGISTER EMAIL
                HStack {
                    ActionButton(title: "REGISTER EMAIL") {
                        Pushwoosh.sharedInstance().setEmail(textInputEmail)
                    }
                    
                    Spacer()
                    
                    TextField("EMAIL", text: $textInputEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // MARK: - SET LANGUAGE
                HStack {
                    ActionButton(title: "SET LANGUAGE") {
                        Pushwoosh.sharedInstance().setEmail(textInputLanguage)
                    }
                    
                    Spacer()
                    
                    TextField("'en'", text: $textInputEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // MARK: - SHOW PUSH TOKEN
                HStack {
                    GeometryReader { geometry in
                        HStack {
                            ActionButton(title: "SHOW PUSH TOKEN") {
                                showPushToken = true
                            }
                            .alert(isPresented: $showPushToken, content: {
                                alert(title: "TAGS", message: "\(pushToken ?? "Push Token doesn't exist")")
                            })
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - SEND LOCAL NOTIFICATION
                HStack {
                    GeometryReader { geometry in
                        HStack {
                            ActionButton(title: "SEND LOCAL NOTIFICATION") {
                                Notifications.shared.showLocalNotification(title: "Hello", body: "Pushwoosh")
                            }
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - CLEAR NOTIFICATION CENTER
                HStack {
                    GeometryReader { geometry in
                        HStack {
                            ActionButton(title: "CLEAR NOTIFICATION CENTER") {
                                PushNotificationManager.clearNotificationCenter()
                            }
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - STOP SERVER COMMUNICATION
                HStack {
                    GeometryReader { geometry in
                        HStack {
                            ActionButton(title: "STOP SERVER COMMUNICATION") {
                                Pushwoosh.sharedInstance().stopServerCommunication()
                            }
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - START SERVER COMMUNICATION
                HStack {
                    GeometryReader { geometry in
                        HStack {
                            ActionButton(title: "START SERVER COMMUNICATION") {
                                Pushwoosh.sharedInstance().startServerCommunication()
                            }
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - GET APPLICATION CODE
                HStack {
                    GeometryReader { geometry in
                        HStack {
                            let appCode = Pushwoosh.sharedInstance().applicationCode
                            ActionButton(title: "GET APPLICATION CODE") {
                                showAlertAppCode = true
                            }
                            .alert(isPresented: $showAlertAppCode, content: {
                                alert(title: "APPLICATION CODE", message: "\(appCode)")
                            })
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - GET HWID
                HStack {
                    GeometryReader { geometry in
                        HStack {
                            ActionButton(title: "GET HWID") {
                                showHwid = true
                            }
                            .alert(isPresented: $showHwid, content: {
                                alert(title: "HWID", message: "\(hwid)")
                            })
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - GET USER ID
                HStack {
                    GeometryReader { geometry in
                        HStack {
                            ActionButton(title: "GET USER ID") {
                                showUserId = true
                            }
                            .alert(isPresented: $showUserId, content: {
                                alert(title: "USER ID", message: "\(userId)")
                            })
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - SHOW ALERT ENABLED
                HStack {
                    GeometryReader { geometry in
                        HStack {
                            Text("SHOW ALERT")
                                .font(.system(size: 14))
                            Spacer()
                            
                            Toggle("", isOn: $alertEnabled)
                                .onChange(of: alertEnabled) { oldValue, newValue in
                                    alertEnabled = newValue
                                    Pushwoosh.sharedInstance().showPushnotificationAlert = newValue
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: -
    // MARK: -
    
    func alert(title: String, message: String) -> Alert {
        return Alert(
            title: Text("\(title)"),
            message: Text("\(message)"),
            dismissButton: .default(Text("OK"))
        )
    }
    
}

struct ActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.blue)
                .font(.system(size: 15, weight: .bold))
                .cornerRadius(10.0)
        }
    }
}

#Preview {
    Actions()
}
