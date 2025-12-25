//
//  TimeCycleApp.swift
//  TimeCycle
//
//  Created by AMOSQIANG on 19/8/2024.
//

import SwiftUI

@main
struct TimeCycleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var timerManager = TimerManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(timerManager: timerManager)
        }
    }
}
