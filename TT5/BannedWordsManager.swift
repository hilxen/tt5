//
//  BannedWordsManager.swift
//  TT5
//
//  Created by Hilxen on 1/11/25.
//
import SwiftUI
import SwiftData
import AVFoundation
import NaturalLanguage
import Speech

class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var speechRecognizer: SFSpeechRecognizer?
    var buffer: SFSpeechAudioBufferRecognitionRequest?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        buffer!.endAudio()
    }
}

final class BannedWordsManager: NSObject {
    let synthesizer = AVSpeechSynthesizer()
    let speechDelegate = SpeechDelegate()
    
    override init() {
        super.init()
        synthesizer.delegate = speechDelegate
//        for locale in SFSpeechRecognizer.supportedLocales() {
//            print(locale)
//        }
    }

    func check(text: String,
               settings: Settings,
               enabledLanguages: [Language],
               bannedWords: [BannedWord],
               complete: @escaping (_ transcription: String, _ matches: [String], _ notMatches: [String], _ voiceId: String) -> Void) {
        let speechTools = AudioManager.shared.speechTools
        var voiceId: String
        let voice = settings.voice
        var language = "en"
        if speechTools.recognizer.languageConstraints.count > 1 {
            speechTools.recognizer.processString(text)
            language = speechTools.recognizer.dominantLanguage?.rawValue ?? speechTools.recognizer.languageConstraints.first!.rawValue
            voiceId = speechTools.voices[language]?[voice] ?? speechTools.voices.values.first?[voice] ?? "com.apple.voice.compact.en-US.Samantha"
        } else {
            language = speechTools.voices.keys.first ?? "en"
            voiceId = speechTools.voices.values.first?[voice] ?? "com.apple.voice.compact.en-US.Samantha"
        }
        var localeId = "en-US"
        for enabledLanguage in enabledLanguages {
            if enabledLanguage.languageCode() == language {
                localeId = enabledLanguage.name
            }
        }
        AudioManager.shared.activateSession()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = false
        recognitionRequest.requiresOnDeviceRecognition = true
        speechDelegate.buffer = recognitionRequest
        speechDelegate.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId))!
        synthesizer.write(utterance) { (buffer: AVAudioBuffer) in
            let pcmBuffer = buffer as? AVAudioPCMBuffer
            recognitionRequest.append(pcmBuffer!)
        }
        if speechDelegate.speechRecognizer!.isAvailable {
            speechDelegate.speechRecognizer!.supportsOnDeviceRecognition = true
            speechDelegate.speechRecognizer!.recognitionTask(with: recognitionRequest) { result, error in
                guard let result = result else {
                    print("There was an error: \(error.debugDescription)")
                    complete("", [], [], voiceId)
                    return
                }
                DispatchQueue.main.async {
                    let isFinal = result.isFinal
                    print("isFinal = \(isFinal) Text \(result.bestTranscription.formattedString)")
                    result.transcriptions.forEach { print($0.formattedString) }
                    var matches: [String] = []
                    var notMatches: [String] = []
                    let words: [String] = result.bestTranscription.formattedString.components(separatedBy: " ")
                    for bannedWord in bannedWords {
                        for word in words {
                            if bannedWord.match(word) {
                                matches.append(bannedWord.pattern)
                            } else if !notMatches.contains(word){
                                notMatches.append(word)
                            }
                        }
                    }
                    complete(result.bestTranscription.formattedString, matches, notMatches, voiceId)
                }
            }
        }
    }
}
