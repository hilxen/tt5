//
//  AudioManager.swift
//  TT5
//
//  Created by Hilxen on 12/7/24.
//

import Foundation
import AVFoundation
import NaturalLanguage
import Speech

extension String {
    func escapedForXML() -> String {
        let generalEntities = [
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            "\"": "&quot;",
            "'": "&apos;"
        ]
        
        var result = self
        for (unescaped, escaped) in generalEntities {
            result = result.replacingOccurrences(of: unescaped, with: escaped)
        }
        return result
    }
    
    func removeExtraSpaces() -> String {
        return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
    }
}


class SpeechTools {
    let recognizer = NLLanguageRecognizer()
    let synthesizer = AVSpeechSynthesizer()
    var voices: [String: [String: String]] = [:]
}


protocol AudioManagerDelegate {
    func speechStarted(item: Item)
    func speechFinished(item: Item)
}

extension Character {
    /// Checks if a character is rendered as an emoji.
    var isEmoji: Bool {
        // Standard emoji presentation scalars (like 😀)
        let hasEmojiPresentation = unicodeScalars.contains { $0.properties.isEmojiPresentation }
        // Complex emojis (like 👨‍👩‍👧‍👦) often contain multiple scalars
        let isCombinedEmoji = unicodeScalars.count > 1 && unicodeScalars.contains { $0.properties.isEmoji }
        
        return hasEmojiPresentation || isCombinedEmoji
    }
}

func limitRepeatedEmojis(in input: String, maxCount: Int = 2) -> String {
    var emojiCounts = [Character: Int]()
    
    let result = input.filter { char in
        // Only apply the limit if the character is an emoji
        if char.isEmoji {
            let currentCount = emojiCounts[char, default: 0]
            if currentCount < maxCount {
                emojiCounts[char] = currentCount + 1
                return true
            } else {
                return false // Filter out if over limit
            }
        }
        
        // If not an emoji (e.g., a letter or "!"), always keep it
        return true
    }
    return String(result)
}

func removeLinks(from text: String) -> String {
    // Regex pattern for http/https links
    let regex = /https?:\/\/\S+/
    
    // Replace all matches with an empty string
    return text.replacing(regex, with: "")
               .trimmingCharacters(in: .whitespacesAndNewlines)
}

final class AudioManager: NSObject {
    static let shared = AudioManager()
    let speechTools = SpeechTools()
    private var player: AVQueuePlayer?
    private var session = AVAudioSession.sharedInstance()
    private var volume: Int = 5
    private var log: Log?
    private var lastSpeechEndTime: Date?
    
    let bannedWordsManager = BannedWordsManager()
    let volumes: [Float] = [0.01, 0.0151, 0.04, 0.08, 0.16, 0.32, 1, 4, 16, 32, 64]
    let ssmlVolumes: [String] = ["silent", "-36dB", "-27dB", "-18dB", "-9dB", "+0dB", "+9dB", "+18dB", "+27dB", "+36dB", "+44dB"]

    var utterances: [AVSpeechUtterance: Item] = [:]
    var delegate: AudioManagerDelegate?
    
    override init() {
        super.init()
        speechTools.synthesizer.delegate = self
    }
    
    func setLog(_ log: Log) {
        self.log = log
        bannedWordsManager.log = log
    }
    
    func activateSession() {
        try? session.setCategory(
            .playback,
            mode: .default,
            options: [.duckOthers]
        )
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        try? session.overrideOutputAudioPort(.speaker)
    }
    
    func removeExcessiveEmotes(item: Item) -> String {
        let maxAllowedEmotes = 2
        var result = Array(item.message)
        if item.emotes.count > maxAllowedEmotes {
            var coutedEmotes = 0
            for emote in item.emotes {
                if coutedEmotes >= maxAllowedEmotes {
                    result.removeSubrange((emote.start)..<(emote.end + 1))
                    result.insert(contentsOf: Array(String(repeating: " ", count: emote.end - emote.start + 1)), at: emote.start)
                }
                coutedEmotes += 1
            }
        }
        return String(result).removeExtraSpaces()
    }
    
    func replaceListedCharactersWithSpaces(_ text: String, charactersToReplace: CharacterSet) -> String {
        return text.unicodeScalars.map { charactersToReplace.contains($0) ? UnicodeScalar(32)! : $0 }.map {
            "\($0)"
        }.joined()
    }
    
    func removeExtraRepetitions(_ text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var result = [String]()
        var currentStreak = [String]()
        
        for word in words {
            if let last = currentStreak.last, last == word {
                if currentStreak.count < 2 {
                    currentStreak.append(word)
                }
            } else {
                if !currentStreak.isEmpty {
                    result.append(contentsOf: currentStreak.prefix(2))
                }
                currentStreak = [word]
            }
        }
        
        // Handle the last streak
        if !currentStreak.isEmpty {
            result.append(contentsOf: currentStreak.prefix(2))
        }
        
        return result.joined(separator: " ")
    }
    
    func findPronunciation(name: String, nicks:[Nick]) -> String? {
        let pronunciation = nicks.first(where: { $0.name.localizedLowercase == name.dropFirst().localizedLowercase })?.pronunciation ?? ""
        return !pronunciation.isEmpty ? "@\(pronunciation)": nil
    }
    
    func replaceAtWords(text: String, nicks: [Nick]) -> String {
        var result = text
        var ranges = [Range<String.Index>]()
        var currentIndex = text.startIndex
        
        while currentIndex < text.endIndex {
            let start = currentIndex
            if text[currentIndex] == "@" {
                // Move to next character to check if it's part of a word
                currentIndex = text.index(after: currentIndex)
                while currentIndex < text.endIndex && isWordCharacter(text[currentIndex]) {
                    currentIndex = text.index(after: currentIndex)
                }
                let end = currentIndex
                ranges.append(start..<end)
            } else {
                // Skip to the next non-space character if not starting with @
                currentIndex = text.index(after: currentIndex)
            }
            
            // Move to the next potential word start
            while currentIndex < text.endIndex && !isWordCharacter(text[currentIndex]) && text[currentIndex] != "@" {
                currentIndex = text.index(after: currentIndex)
            }
        }
        
        // Replace @words in reverse order to avoid index shifting
        for range in ranges.reversed() {
            let word = String(text[range])
            if let replacement = findPronunciation(name: word, nicks: nicks) {
                result.replaceSubrange(range, with: replacement)
            }
        }
        
        return result
    }

    func isWordCharacter(_ char: Character) -> Bool {
        return char.isLetter || char.isNumber || char == "_"
    }
    
    func cleanText(nicks: [Nick], item: Item) -> String {
        var text = removeExcessiveEmotes(item: item)
        text = limitRepeatedEmojis(in: text)
        text = replaceAtWords(text: text, nicks: nicks)
        text = removeLinks(from: text)
        let charactersToReplace = CharacterSet(charactersIn: "[]{}/|\\~^&;")
        let cleanedText = removeExtraRepetitions(
            replaceListedCharactersWithSpaces(text, charactersToReplace: charactersToReplace))
        return cleanedText
    }

    func textToSpeech(settings: Settings, nicks: [Nick], item: Item,
                      bannedWords: [BannedWord],
                      enabledLanguages: [Language]) {
        let nick = item.nick
        if utterances.count > 5 {
            log?.print("speech skipped", nick.name, "queue", String(utterances.count), "> 5")
            item.skipped = true
            return
        }
        if !nick.defaults && nick.muted {
            log?.print("nick muted", nick.name)
            item.skipped = true
            return
        }
        if nick.muted {
            if (nick.mod! && settings.mods)
                || (nick.vip! && settings.vips)
                || (nick.subscriber! && settings.subscribers)
                || (nick.mod! && settings.mods)
                || (nick.broadcaster! && settings.broadcaster)
                || (item.messageId == "highlighted-message" && settings.highlighted)
                || (item.customReward != nil && settings.customRewards ?? true){
                log?.print("nick unmuted by role", nick.name)
            } else {
                log?.print("nick muted by default", nick.name)
                item.skipped = true
                return
            }
        }
        if (item.conversation && settings.muteConversations ?? false) {
            log?.print("conversation skipped")
            item.skipped = true
            return
        }
        if (item.message.starts(with: "!")) {
            log?.print("command skipped")
            item.skipped = true
            return
        }
        let cleanedText = cleanText(nicks: nicks, item: item)
        if (settings.bannedWordsEnabled ?? false) && SFSpeechRecognizer.authorizationStatus() == .authorized && !bannedWords.isEmpty {
            bannedWordsManager.check(
                text: "\(nick.pronunciationOfName()) \(cleanedText)",
                settings: settings,
                enabledLanguages: enabledLanguages,
                bannedWords: bannedWords,
                complete: ({ transcription, matchedBannedWords, notMatchedWords, voiceId in
                if matchedBannedWords.isEmpty {
                    self.speak(settings: settings, nick: nick, item: item, cleanedText: cleanedText)
                } else {
                    item.containsBannedWords = true
                    item.skipped = true
                    item.message.append("⛔️\(matchedBannedWords.joined(separator: " ⛔️"))")
                }
            }))
        } else {
            speak(settings: settings, nick: nick, item: item, cleanedText: cleanedText)
        }
    }
    
    func speak(settings: Settings, nick: Nick, item: Item, cleanedText: String) {
        var volumeIndex = settings.volume + nick.volume!
        if volumeIndex < 0 { volumeIndex = 0 }
        else if volumeIndex > volumes.endIndex { volumeIndex = volumes.endIndex }

        let ssmlRate = Rate.ssml(rawValue: nick.rate!)
        let ssmlPitch = Pitch.fromRawValue(rawValue: nick.pitch!).ssml()
        let ssmlVolume = ssmlVolumes[volumeIndex]
        var customRewardProsody = ""
        let customReward = item.customReward
        if customReward != nil && customReward!.announce && !customReward!.name.isEmpty {
            let customRewardName = item.customReward!.name.escapedForXML()
            customRewardProsody = "<prosody volume='\(ssmlVolume)' pitch='\(ssmlPitch)' rate='\(ssmlRate)'>\(customRewardName)</prosody><break/>"
        }
        
        let needsExtraPriming = isBluetoothRoute && (outputLatency > 0.7 || timeSinceLastSpeech > 10)
        let primingBreak = needsExtraPriming ? "<break time='1.5s'/>" : "<break time='0.8s'/>"
        
        let ssml = "<speak>\(primingBreak)<prosody volume='\(ssmlVolume)' pitch='\(ssmlPitch)' rate='\(ssmlRate)'>\(nick.pronunciationOfName())</prosody><break/>\(customRewardProsody)<prosody volume='\(ssmlVolume)' pitch='\(ssmlPitch)' rate='\(ssmlRate)'>\(cleanedText.escapedForXML())</prosody></speak>"
        log?.print(ssml)

        var voiceId: String
        if speechTools.recognizer.languageConstraints.count > 1 {
            speechTools.recognizer.processString(cleanedText)
            let language = speechTools.recognizer.dominantLanguage?.rawValue ?? speechTools.recognizer.languageConstraints.first!.rawValue
            voiceId = speechTools.voices[language]?[nick.voice!] ?? speechTools.voices.values.first?[nick.voice!] ?? "com.apple.voice.compact.en-US.Samantha"
        } else {
            voiceId = speechTools.voices.values.first?[nick.voice!] ?? "com.apple.voice.compact.en-US.Samantha"
        }
        log?.print("queued speech", nick.name, nick.voice!,
              "volume", ssmlVolume, String(volumes[volumeIndex]),
              "rate", ssmlRate, String(nick.rate!),
              "pitch", String(ssmlPitch), String(nick.pitch!),
              "queue size", String(utterances.count))
        
        DispatchQueue.global(qos: .background).async {
            self.speak(item: item, voiceId: voiceId, ssml: ssml)
        }
    }
    
    class AudioCallbackContext {
        let audioManager: AudioManager
        let utterance: AVSpeechUtterance
        
        init(audioManager: AudioManager, utterance: AVSpeechUtterance) {
            self.audioManager = audioManager
            self.utterance = utterance
        }
    }
    
    func speak(item: Item, voiceId: String, ssml: String) {
        activateSession()
        let utterance = AVSpeechUtterance(ssmlRepresentation: ssml)!
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
        utterances[utterance] = item
        if item.customReward != nil && item.customReward!.sound != Sound.No_Sound.rawValue {
            let tmpSoundID: SystemSoundID = SystemSoundID(item.customReward!.sound)
            let context = UnsafeMutableRawPointer(Unmanaged.passRetained(AudioCallbackContext(audioManager: self, utterance: utterance)).toOpaque())
            let completionCallback: AudioServicesSystemSoundCompletionProc = { (inSystemSoundID, clientData) in
                let context = Unmanaged<AudioCallbackContext>.fromOpaque(clientData!).takeRetainedValue()
                context.audioManager.speechTools.synthesizer.speak(context.utterance)
                AudioServicesRemoveSystemSoundCompletion(inSystemSoundID)
            }
            AudioServicesAddSystemSoundCompletion(tmpSoundID, nil, nil, completionCallback, context)
            AudioServicesPlaySystemSound(tmpSoundID)
        } else {
            speechTools.synthesizer.speak(utterance)
        }
        
    }
    
    func announce(settings: Settings, text: String, voiceId: String? = nil) {
        var volumeIndex = settings.volume
        if volumeIndex < 0 { volumeIndex = 0 }
        else if volumeIndex > volumes.endIndex { volumeIndex = volumes.endIndex }

        let ssmlRate = Rate.ssml(rawValue: settings.rate)
        let ssmlPitch = Pitch.fromRawValue(rawValue: settings.pitch).ssml()
        let ssmlVolume = ssmlVolumes[volumeIndex]
        let needsExtraPriming = isBluetoothRoute && (outputLatency > 0.7 || timeSinceLastSpeech > 10)
        let primingBreak = needsExtraPriming ? "<break time='1.5s'/>" : "<break time='0.8s'/>"
        let ssml = "<speak>\(primingBreak)<prosody volume='\(ssmlVolume)' pitch='\(ssmlPitch)' rate='\(ssmlRate)'>\(text.escapedForXML())</prosody></speak>"

        activateSession()
        let useVoiceId = voiceId ?? speechTools.voices.values.first?[settings.voice] ?? "com.apple.voice.compact.en-US.Samantha"
        let utterance = AVSpeechUtterance(ssmlRepresentation: ssml)!
        utterance.voice = AVSpeechSynthesisVoice(identifier: useVoiceId)
        speechTools.synthesizer.speak(utterance)
    }
    
    func startAudio(url: String) {
        activateSession()
        let url = URL(string: url)
        let playerItem: AVPlayerItem = AVPlayerItem(url: url!)
        if let player = player {
            player.insert(playerItem, after: nil)
        } else {
            player = AVQueuePlayer(playerItem: playerItem)
        }
        if let player = player {
            player.volume = volumes[volume]
            player.play()
        }
    }
    
    func deactivateSession() {
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch let error as NSError {
            log?.print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    var isBluetoothRoute: Bool {
        return session.currentRoute.outputs.contains { output in
            let bluetoothPorts: Set<AVAudioSession.Port> = [
                .bluetoothA2DP,     // High-quality playback (what you usually want for TTS/speech)
                .bluetoothHFP,      // Voice calls / lower quality but duplex
                .bluetoothLE        // LE Audio (iOS 13+, some newer devices)
            ]
            return bluetoothPorts.contains(output.portType)
        }
    }
    
    var outputLatency: TimeInterval {
        AVAudioSession.sharedInstance().outputLatency
    }

    var timeSinceLastSpeech: TimeInterval {
        lastSpeechEndTime.map { Date().timeIntervalSince($0) } ?? 999
    }
}

extension AudioManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        if let item = utterances[utterance] {
            log?.print("started speaking", item.nick.name, "queue size", String(utterances.count))
            delegate?.speechStarted(item: item)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        lastSpeechEndTime = Date()
        if let item = utterances.removeValue(forKey: utterance) {
            log?.print("stopped speaking", item.nick.name, "queue size", String(utterances.count))
            delegate?.speechFinished(item: item)
        }
    }
}
