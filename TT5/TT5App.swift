//
//  TT5App.swift
//  TT5
//
//  Copyright (c) Hilxen. MIT License.
//

import SwiftUI
import SwiftData

@main
struct TT5App: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Settings.self, Nick.self, Language.self, Channel.self, BannedWord.self, LogItem.self, CustomReward.self])
    }
}
