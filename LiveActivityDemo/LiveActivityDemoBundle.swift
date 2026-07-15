//
//  LiveActivityDemoBundle.swift
//  LiveActivityDemo
//
//  Created by André Kis on 21.05.26.
//

import WidgetKit
import SwiftUI

@main
struct LiveActivityDemoBundle: WidgetBundle {
    var body: some Widget {
        LiveActivityDemo()
        LiveActivityDemoLiveActivity()
        FIFAMatchActivity()
        RadioBroadcastActivity()
        DefaultLiveActivity()
    }
}
