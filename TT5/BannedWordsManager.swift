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
    let recognizer = NLLanguageRecognizer()
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
               complete: @escaping (_ transcription: String, _ matchedBannedWords: [String], _ notMatchedWords: [String], _ voiceId: String) -> Void) {
        var voiceId: String
        let voice = settings.voice
        var language = "en"
        recognizer.languageConstraints = enabledLanguages.map({NLLanguage($0.languageCode())})
        var enabledVoices = [String: [String: String]]()
        for language in enabledLanguages {
            enabledVoices[language.languageCode()] = [
                "female": language.femaleVoiceId ?? language.maleVoiceId!,
                "male": language.maleVoiceId ?? language.femaleVoiceId!
            ]
        }
        if recognizer.languageConstraints.count > 1 {
            recognizer.processString(text)
            language = recognizer.dominantLanguage?.rawValue ?? recognizer.languageConstraints.first!.rawValue
            voiceId = enabledVoices[language]?[voice] ?? enabledVoices.values.first?[voice] ?? "com.apple.voice.compact.en-US.Samantha"
        } else {
            language = enabledVoices.keys.first ?? "en"
            voiceId = enabledVoices.values.first?[voice] ?? "com.apple.voice.compact.en-US.Samantha"
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
                    var matchedBannedWords: [String] = []
                    var notMatchedWords: [String] = []
                    var matchedWords: [String] = []
                    let words: [String] = result.bestTranscription.formattedString.components(separatedBy: " ")
                    if bannedWords.isEmpty {
                        for word in words {
                            notMatchedWords.append(word)
                        }
                    }
                    else {
                        for bannedWord in bannedWords {
                            for word in words {
                                if bannedWord.match(word) {
                                    if !matchedWords.contains(word) {
                                        matchedWords.append(word)
                                    }
                                    if !matchedBannedWords.contains(bannedWord.pattern) {
                                        matchedBannedWords.append(bannedWord.pattern)
                                    }
                                }
                            }
                        }
                        for bannedWord in bannedWords {
                            for word in words {
                                if !matchedWords.contains(word) && !notMatchedWords.contains(word){
                                    notMatchedWords.append(word)
                                }
                            }
                        }
                    }
                    complete(result.bestTranscription.formattedString, matchedBannedWords, notMatchedWords, voiceId)
                }
            }
        }
    }
}
