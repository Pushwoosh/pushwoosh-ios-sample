//
//  ContentView.swift
//  newdemo
//
//  Created by Andrew Kis on 12.4.24..
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            Actions()
                .tabItem {
                    Image(systemName: "figure")
                    Text("Actions")
                }
                .tag(0)
            
            Settings()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
