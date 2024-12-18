//
//  Settings.swift
//  TT5
//
//  Created by Hilxen on 12/8/24.
//

import Foundation
import SwiftData


@Model
final class Settings {
    var channel: String
    var volume: Int
    var muted: Bool
    var rate: Float?
    var pitch: Float?
    var gender: String?
    
    init(channel: String, volume: Int, muted: Bool) {
        self.channel = channel
        self.volume = volume
        self.muted = muted
    }
    
    func set(_settings: Settings) {
        self.channel = _settings.channel
        self.volume = _settings.volume
        self.muted = _settings.muted
    }
}


@Model
final class Nick {
    var nick: String
    var muted: Bool
    var pronunciation: String?
    var volume: Int?
    var rate: Float?
    var pitch: Float?
    var gender: String?
    
    init(nick: String, muted: Bool) {
        self.nick = nick
        self.muted = muted
    }
}
