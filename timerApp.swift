//
//  timerApp.swift
//  timer
//
//  Created by Shehryar Manzar on 2026-09-14.
//

import SwiftUI

@main
struct timerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
