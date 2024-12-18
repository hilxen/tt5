//
//  AudioManager.swift
//  TT5
//
//  Created by Hilxen on 12/7/24.
//

import Foundation
import AVFoundation
import NaturalLanguage


final class AudioManager {
    static let shared = AudioManager()
    let recognizer = NLLanguageRecognizer()
    let synthesizer = AVSpeechSynthesizer()
    let languages: [NLLanguage: String] = [
            .english: "en-US",
            .russian: "ru-RU",
//            .german: "de-DE",
//            .italian: "it-IT",
//            .french: "fr-FR",
//            .spanish: "es-ES"
    ]
    let voices = [
        "de": "com.apple.ttsbundle.siri_Helena_de-DE_compact",
        "fr": "com.apple.ttsbundle.siri_Marie_fr-FR_compact",
        "it": "com.apple.voice.compact.it-IT.Alice",
        "en": "com.apple.voice.compact.en-US.Samantha",
        "es": "com.apple.voice.compact.es-ES.Monica",
        "ru": "com.apple.voice.compact.ru-RU.Milena"
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
    let volumes: [Float] = [0.01, 0.02, 0.04, 0.08, 0.16, 0.32, 1, 4, 16, 32, 64]
    
    private init() {
        recognizer.languageConstraints = Array(languages.keys)
        let supportedVoices = AVSpeechSynthesisVoice.speechVoices() //list of supported voices
        for (language, locale) in languages {
            for supportedVoice in supportedVoices {
                if supportedVoice.language == locale && supportedVoice.gender == .female {
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
    
    func setVolume(_ volume: Int) {
        self.volume = volume
    }
    
    func textToSpeech(text: String) {
        activateSession()
        let utterance = AVSpeechUtterance(string: text)
        // Configure the utterance.
        //utterance.rate = 0.5
        //utterance.pitchMultiplier = 0.5
        //utterance.postUtteranceDelay = 0.2
        utterance.volume = volumes[volume]

        recognizer.processString(text)
        let language = recognizer.dominantLanguage?.rawValue ?? "en"
        let voiceId = voices[language]
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId!)
        synthesizer.speak(utterance)

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
            player.volume = 10.0 * Float(volume)
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
