//
//  TT5App.swift
//  TT5
//
//  Copyright (c) Hilxen. MIT License.
//

import SwiftUI
import SwiftData

/// App Store artwork (logo, role badges) is kept out of the public repo as "<name>Store" assets.
/// Returns that asset's name when it is bundled, otherwise the name of the placeholder asset.
func storeImageName(_ name: String) -> String {
    UIImage(named: name + "Store") != nil ? name + "Store" : name
}

@main
struct TT5App: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Settings.self, Nick.self, Language.self, Channel.self, BannedWord.self, LogItem.self, CustomReward.self])
    }
}
