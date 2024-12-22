//
//  AudioManager.swift
//  TT5
//
//  Created by Hilxen on 12/7/24.
//

import Foundation
import AVFoundation
import NaturalLanguage

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
}


final class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    let speechTools = SpeechTools()
    let languages: [NLLanguage: String] = [
            .english: "en-US",
            .russian: "ru-RU",
//            .german: "de-DE",
//            .italian: "it-IT",
//            .french: "fr-FR",
//            .spanish: "es-ES"
    ]
    let voices = [
        "de": ["female": "com.apple.ttsbundle.siri_Helena_de-DE_compact", "male": "com.apple.ttsbundle.siri_Martin_de-DE_compact"],
        "fr": ["female": "com.apple.ttsbundle.siri_Marie_fr-FR_compact", "male": "com.apple.voice.compact.fr-FR.Thomas"],
        "it": ["female": "com.apple.voice.compact.it-IT.Alice", "male": "com.apple.eloquence.it-IT.Rocko"],
        "en": ["female": "com.apple.voice.compact.en-US.Samantha", "male": "com.apple.speech.synthesis.voice.Fred"],
        "es": ["female": "com.apple.voice.compact.es-ES.Monica", "male": "com.apple.eloquence.es-ES.Rocko"],
        "ru": ["female": "com.apple.voice.compact.ru-RU.Milena", "male": "com.apple.voice.compact.ru-RU.Milena"],
    ]
//    it-IT female com.apple.voice.compact.it-IT.Alice
//    fr-FR female com.apple.ttsbundle.siri_Marie_fr-FR_compact
//    de-DE female com.apple.ttsbundle.siri_Helena_de-DE_compact
//    de-DE female com.apple.voice.compact.de-DE.Anna
//    ru-RU female com.apple.voice.compact.ru-RU.Milena
//    en-US female com.apple.ttsbundle.siri_Nicky_en-US_compact
//    en-US female com.apple.voice.compact.en-US.Samantha
//    es-ES female com.apple.voice.compact.es-ES.Monica

    private var player: AVQueuePlayer?
    private var session = AVAudioSession.sharedInstance()
    private var volume: Int = 5
    let volumes: [Float] = [0.005, 0.02, 0.04, 0.08, 0.16, 0.32, 1, 4, 16, 32, 64]
    let ssmlVolumes: [String] = ["silent", "-36dB", "-27dB", "-18dB", "-9dB", "+0dB", "+9dB", "+18dB", "+27dB", "+36dB", "+45dB"]

    var utterances: [AVSpeechUtterance: Nick] = [:]
    @Published var speakerNick: Nick?
    @Published var speakerActive: Bool = false
    @Published var speakerCountdown: Int = -1
    var contentViewActive: Bool = false
    
    override init() {
        super.init()
        speechTools.synthesizer.delegate = self
        speechTools.recognizer.languageConstraints = Array(languages.keys)
        let supportedVoices = AVSpeechSynthesisVoice.speechVoices() //list of supported voices
        for (_, locale) in languages {
            for supportedVoice in supportedVoices {
                if supportedVoice.language == locale /* && (supportedVoice.gender == .female || supportedVoice.gender == .male) */ {
                    let gender = supportedVoice.gender == .female ? "female" : supportedVoice.gender == .male ? "male" : "unknown"
                    print(locale, gender, supportedVoice.identifier)
                }
            }
        }
        print("min rate", AVSpeechUtteranceMinimumSpeechRate, "default", AVSpeechUtteranceDefaultSpeechRate, "max rate", AVSpeechUtteranceMaximumSpeechRate)
    }
    
    private func activateSession() {
        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers]
            )
        } catch _ {}
        
        do {
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch _ {}
        
        do {
            try session.overrideOutputAudioPort(.speaker)
        } catch _ {}
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
        let pronunciation = nicks.first(where: { $0.name == name.dropFirst() })?.pronunciation ?? ""
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

    func textToSpeech(settings: Settings, nicks: [Nick], item: Item) {
        let nick = item.nick
        if utterances.count > 5 {
            print("speech skipped", nick.name, "queue", utterances.count, "> 5")
            item.skipped = true
            return
        }
        if !nick.defaults && nick.muted {
            print("nick muted", nick.name)
            item.skipped = true
            return
        }
        if nick.muted {
            if (nick.mod! && settings.mods)
                || (nick.vip! && settings.vips)
                || (nick.subscriber! && settings.subscribers)
                || (nick.mod! && settings.mods)
                || (nick.broadcaster! && settings.broadcaster)
                || (item.messageId == "highlighted-message" && settings.highlighted) {
                print("nick unmuted by role", nick.name)
            } else {
                print("nick muted by default", nick.name)
                item.skipped = true
                return
            }
        }
        activateSession()
        let mappedText1 = removeExcessiveEmotes(item: item)
        let mappedText2 = replaceAtWords(text: mappedText1, nicks: nicks)
        let charactersToReplace = CharacterSet(charactersIn: "[]{}/|\\~^&;")
        let cleanedText = removeExtraRepetitions(
            replaceListedCharactersWithSpaces(mappedText2, charactersToReplace: charactersToReplace))
        
        var volumeIndex = settings.volume + nick.volume!
        if volumeIndex < 0 { volumeIndex = 0 }
        else if volumeIndex > volumes.endIndex { volumeIndex = volumes.endIndex }

        let ssmlRate = Rate.fromRawValue(rawValue: nick.rate!).ssml()
        let ssmlPitch = Pitch.fromRawValue(rawValue: nick.pitch!).ssml()
        let ssmlVolume = ssmlVolumes[volumeIndex]
        let ssml = "<speak><prosody volume='\(ssmlVolume)' pitch='\(ssmlPitch)' rate='\(ssmlRate)'>\(nick.pronunciationOfName())</prosody><break/><prosody volume='\(ssmlVolume)' pitch='\(ssmlPitch)' rate='\(ssmlRate)'>\(cleanedText.escapedForXML())</prosody></speak>"
        print(ssml)
        let utterance = AVSpeechUtterance(ssmlRepresentation: ssml)!
        
        utterance.prefersAssistiveTechnologySettings = true
        //utterance.volume = volumes[volumeIndex]
        speechTools.recognizer.processString(cleanedText)
        let language = speechTools.recognizer.dominantLanguage?.rawValue ?? "en"
        let voiceId = voices[language]![nick.voice!]
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId!)
        utterances[utterance] = nick
        print("queued speech", nick.name, nick.voice!, "volume", ssmlVolume, "rate", ssmlRate, "pitch", ssmlPitch, "queue size", utterances.count)
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
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}

extension AudioManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let nick = utterances[utterance]!
        speakerNick = nick
        if contentViewActive {
            speakerActive = true
        }
        speakerCountdown = -1
        print("started speaking", nick.name, "queue size", utterances.count)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let nick = utterances.removeValue(forKey: utterance)!
        speakerCountdown = 2
        print("stopped speaking", nick.name, "queue size", utterances.count)
    }
}
