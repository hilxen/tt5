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
    case min = 0.2
    case normal = 0.5
    case max = 1.0
    static let step: Float = 0.05
    
    static func ssml(rawValue: Float) -> String {
        let percent = Int(rawValue * 200)
        return "\(percent)%"
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
final class Settings: Codable {
    enum CodingKeys: CodingKey {
        case channel
        case volume
        case muted
        case rate
        case pitch
        case voice
        case mods
        case vips
        case subscribers
        case broadcaster
        case highlighted
        case version
        case bannedWordsEnabled
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decode(String.self, forKey: .channel)
        volume = try container.decode(Int.self, forKey: .volume)
        muted = try container.decode(Bool.self, forKey: .muted)
        rate = try container.decode(Float.self, forKey: .rate)
        pitch = try container.decode(Float.self, forKey: .pitch)
        voice = try container.decode(String.self, forKey: .voice)
        mods = try container.decode(Bool.self, forKey: .mods)
        vips = try container.decode(Bool.self, forKey: .vips)
        subscribers = try container.decode(Bool.self, forKey: .subscribers)
        broadcaster = try container.decode(Bool.self, forKey: .broadcaster)
        highlighted = try container.decode(Bool.self, forKey: .highlighted)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        bannedWordsEnabled = try container.decodeIfPresent(Bool.self, forKey: .bannedWordsEnabled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(channel, forKey: .channel)
        try container.encode(volume, forKey: .volume)
        try container.encode(muted, forKey: .muted)
        try container.encode(rate, forKey: .rate)
        try container.encode(pitch, forKey: .pitch)
        try container.encode(voice, forKey: .voice)
        try container.encode(mods, forKey: .mods)
        try container.encode(vips, forKey: .vips)
        try container.encode(subscribers, forKey: .subscribers)
        try container.encode(broadcaster, forKey: .broadcaster)
        try container.encode(highlighted, forKey: .highlighted)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(bannedWordsEnabled, forKey: .bannedWordsEnabled)
    }
    
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
    var version: String?
    var bannedWordsEnabled: Bool?
    
    init(channel: String, volume: Int, muted: Bool, rate: Rate, pitch: Pitch, voice: Voice,
         mods: Bool, vips: Bool, subscribers: Bool, broadcaster: Bool, highlighted: Bool, bannedWordsEnabled: Bool) {
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
        self.bannedWordsEnabled = bannedWordsEnabled
    }
    
    init(_ copy: Settings) {
        self.channel = copy.channel
        self.volume = copy.volume
        self.muted = copy.muted
        self.rate = copy.rate
        self.pitch = copy.pitch
        self.voice = copy.voice
        self.mods = copy.mods
        self.vips = copy.vips
        self.subscribers = copy.subscribers
        self.broadcaster = copy.broadcaster
        self.highlighted = copy.highlighted
        self.bannedWordsEnabled = copy.bannedWordsEnabled
    }
    
    func set(_ copy: Settings) {
        self.channel = copy.channel
        self.volume = copy.volume
        self.muted = copy.muted
        self.rate = copy.rate
        self.pitch = copy.pitch
        self.voice = copy.voice
        self.mods = copy.mods
        self.vips = copy.vips
        self.subscribers = copy.subscribers
        self.broadcaster = copy.broadcaster
        self.highlighted = copy.highlighted
        self.bannedWordsEnabled = copy.bannedWordsEnabled
    }
}


@Model
final class Nick: Identifiable, Codable {
    enum CodingKeys: CodingKey {
        case name
        case defaults
        case muted
        case pronunciation
        case volume
        case rate
        case pitch
        case voice
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        defaults = try container.decode(Bool.self, forKey: .defaults)
        muted = try container.decode(Bool.self, forKey: .muted)
        pronunciation = try container.decodeIfPresent(String.self, forKey: .pronunciation)
        volume = try container.decodeIfPresent(Int.self, forKey: .volume)
        rate = try container.decodeIfPresent(Float.self, forKey: .rate)
        pitch = try container.decodeIfPresent(Float.self, forKey: .pitch)
        voice = try container.decodeIfPresent(String.self, forKey: .voice)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(defaults, forKey: .defaults)
        try container.encode(muted, forKey: .muted)
        try container.encodeIfPresent(volume, forKey: .volume)
        try container.encodeIfPresent(pronunciation, forKey: .pronunciation)
        try container.encodeIfPresent(rate, forKey: .rate)
        try container.encodeIfPresent(pitch, forKey: .pitch)
        try container.encodeIfPresent(voice, forKey: .voice)
    }
    
    @Attribute(.unique)
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
    
    func set(overrideDefaults: Bool, muted: Bool, pronunciation: String, voice: Voice, rateValue: Float, pitch: Pitch, volume: Volume) {
        self.pronunciation = pronunciation
        if overrideDefaults {
            self.muted = muted
            self.voice = voice.rawValue
            self.pitch = pitch.rawValue
            self.rate = rateValue
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


@Model
final class Language: Identifiable, Codable {
    enum CodingKeys: CodingKey {
        case name
        case enabled
        case femaleVoiceId
        case maleVoiceId
        case voiceIds
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        femaleVoiceId = try container.decodeIfPresent(String.self, forKey: .femaleVoiceId)
        maleVoiceId = try container.decodeIfPresent(String.self, forKey: .maleVoiceId)
        voiceIds = try container.decode([VoiceId].self, forKey: .voiceIds)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(enabled, forKey: .enabled)
        try container.encodeIfPresent(femaleVoiceId, forKey: .femaleVoiceId)
        try container.encodeIfPresent(maleVoiceId, forKey: .maleVoiceId)
        try container.encode(voiceIds, forKey: .voiceIds)
    }

    var name: String
    var enabled: Bool
    var femaleVoiceId: String?
    var maleVoiceId: String?
    var voiceIds: [VoiceId] = []
    
    var id: String {
        return name
    }
    
    init(name: String, enabled: Bool) {
        self.name = name
        self.enabled = enabled
    }
    
    func displayName() -> String {
        return Locale.current.localizedString(forIdentifier: name)!
    }
    
    func languageCode() -> String {
        return name.components(separatedBy: "-")[0]
    }
}

struct VoiceId: Codable, Hashable, Identifiable {
    let id: String
    let gender: String

    init(id: String, gender: String) {
        self.id = id
        self.gender = gender
    }
}


@Model
final class Channel: Identifiable, Codable {
    enum CodingKeys: CodingKey {
        case name
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
    
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    var id: String {
        return name
    }
}


@Model
final class BannedWord: Identifiable, Codable {
    enum CodingKeys: CodingKey {
        case pattern
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pattern = try container.decode(String.self, forKey: .pattern)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pattern, forKey: .pattern)
    }
    
    var pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
    }
    
    var id: String {
        return pattern
    }
    
    func match(_ string: String) -> Bool {
        if pattern.contains("*") || pattern.contains("?") {
            let pred = NSPredicate(format: "self LIKE %@", pattern)
            return !NSArray(object: string).filtered(using: pred).isEmpty
        } else {
            return string.range(of: pattern, options: .caseInsensitive) != nil
        }
    }
}
