//
//  TT5App.swift
//  TT5
//
//  Created by Hilxen on 12/1/24.
//

import SwiftUI
import SwiftData

@main
struct TT5App: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Settings.self, Nick.self, Language.self, Channel.self, BannedWord.self])
    }
}
