//
//  Settings.swift
//  TT5
//
//  Created by Hilxen on 12/8/24.
//

import Foundation
import SwiftData
import SwiftUI


enum Volume: Int, CaseIterable {
    case low = -2
    case normal = 0
    case high = 2
    func description() -> String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
}

enum Rate: Float, CaseIterable {
    case slow = 0.2
    case normal = 0.5
    case fast = 0.8
    case hurried = 1.0
    
    func description() -> String {
        switch self {
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .fast: return "Fast"
        case .hurried: return "Hurried"
        }
    }
    
    func ssml() -> String {
        switch self {
        case .slow: return "50%"
        case .normal: return "default"
        case .fast: return "150%"
        case .hurried: return "200%"
        }
    }
    
    static func fromRawValue(rawValue: Float) -> Rate {
        return .allCases.first(where: {$0.rawValue == rawValue}) ?? .normal
    }
}

enum Pitch: Float, CaseIterable {
    case bass = 0.1
    case low = 0.5
    case normal = 1.0
    case high = 1.5
    case soprano = 2.0

    func description() -> String {
        switch self {
        case .bass: return "Bass"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .soprano: return "Soprano"
        }
    }
    
    func ssml() -> String {
        switch self {
        case .bass: return "x-low"
        case .low: return "low"
        case .normal: return "default"
        case .high: return "high"
        case .soprano: return "x-high"
        }
    }

    static func fromRawValue(rawValue: Float) -> Pitch {
        return .allCases.first(where: {$0.rawValue == rawValue}) ?? .normal
    }
}

enum Voice: String, CaseIterable {
    case female = "female"
    case male = "male"
    func description() -> String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        }
    }
}


@Model
final class Settings {
    var channel: String
    var volume: Int
    var muted: Bool
    var rate: Float
    var pitch: Float
    var voice: String
    var mods: Bool
    var vips: Bool
    var subscribers: Bool
    var broadcaster: Bool
    var highlighted: Bool
    
    init(channel: String, volume: Int, muted: Bool, rate: Rate, pitch: Pitch, voice: Voice,
         mods: Bool, vips: Bool, subscribers: Bool, broadcaster: Bool, highlighted: Bool) {
        self.channel = channel
        self.volume = volume
        self.muted = muted
        self.rate = rate.rawValue
        self.pitch = pitch.rawValue
        self.voice = voice.rawValue
        self.mods = mods
        self.vips = vips
        self.subscribers = subscribers
        self.broadcaster = broadcaster
        self.highlighted = highlighted
    }
    
    func set(_settings: Settings) {
        self.channel = _settings.channel
        self.volume = _settings.volume
        self.muted = _settings.muted
        self.rate = _settings.rate
        self.pitch = _settings.pitch
        self.voice = _settings.voice
        self.mods = _settings.mods
        self.vips = _settings.vips
        self.subscribers = _settings.subscribers
        self.broadcaster = _settings.broadcaster
        self.highlighted = _settings.highlighted
    }
}


@Model
final class Nick: Identifiable {
    var name: String
    var defaults: Bool
    var muted: Bool
    var pronunciation: String?
    var volume: Int?
    var rate: Float?
    var pitch: Float?
    var voice: String?
    @Transient var color: String?
    @Transient var vip: Bool?
    @Transient var mod: Bool?
    @Transient var subscriber: Bool?
    @Transient var broadcaster: Bool?
    
    init(name: String, muted: Bool) {
        self.name = name
        self.muted = muted
        self.defaults = true
    }
    
    var id: String {
        return name
    }
    
    func set(overrideDefaults: Bool, muted: Bool, pronunciation: String, voice: Voice, rate: Rate, pitch: Pitch, volume: Volume) {
        self.pronunciation = pronunciation
        if overrideDefaults {
            self.muted = muted
            self.voice = voice.rawValue
            self.pitch = pitch.rawValue
            self.rate = rate.rawValue
            self.volume = volume.rawValue
            self.defaults = false
        } else {
            self.muted = muted
            self.voice = nil
            self.pitch = nil
            self.rate = nil
            self.volume = nil
            self.defaults = true
        }
    }
    
    func pronunciationOfName() -> String {
        return (pronunciation?.isEmpty ?? true) ? name : pronunciation!
    }
    
    func getColor() -> Color {
        var hexSanitized = self.color!.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return Color.black }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return Color.black
        }

        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
