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
    var defaultMuted: Bool
    
    init(channel: String, volume: Int, defaultMuted: Bool) {
        self.channel = channel
        self.volume = volume
        self.defaultMuted = defaultMuted
    }
    
    func set(_settings: Settings) {
        self.channel = _settings.channel
        self.volume = _settings.volume
        self.defaultMuted = _settings.defaultMuted
    }
}


@Model
final class Nick {
    var nick: String
    var muted: Bool
    
    init(nick: String, muted: Bool) {
        self.nick = nick
        self.muted = muted
    }
}
