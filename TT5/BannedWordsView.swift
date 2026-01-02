//
//  BanwordsView.swift
//  TT5
//
//  Created by Hilxen on 1/7/25.
//

import SwiftUI
import SwiftData
import AVFoundation
import Speech


struct FoundBannedWords: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentation
    @Query private var bannedWords: [BannedWord]
    @Query private var settings: [Settings]
    @State private var multiSelection = Set<String>()

    init(search: [String], showAll: Bool) {
        if showAll {
            self._bannedWords = Query(sort: \.pattern)
        } else if search.count == 1 {
            self._bannedWords = Query(filter: #Predicate<BannedWord> { $0.pattern.localizedStandardContains(search[0]) }, sort: \.pattern)
        } else {
            self._bannedWords = Query(filter: #Predicate<BannedWord> { search.contains($0.pattern) }, sort: \.pattern)
        }
    }
    

    var body: some View {
        List(bannedWords, selection: $multiSelection) { bannedWord in
            HStack {
                Text(bannedWord.pattern)
            }.swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    modelContext.delete(bannedWord)
                    try! modelContext.save()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        if !multiSelection.isEmpty {
            HStack {
                Spacer()
                Button(role: .destructive) {
                    for selected in multiSelection {
                        modelContext.delete(bannedWords.first(where: { $0.pattern == selected })!)
                    }
                    try! modelContext.save()
                    multiSelection.removeAll()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
            }.padding(.horizontal, 20).padding(.top, 10)
        }
    }
}



struct TestBannedWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query(filter: #Predicate<Language> { $0.enabled }) private var enabledLanguages: [Language]
    @Query private var bannedWords: [BannedWord]
    @State private var textForTesting: String = ""
    @State private var matchedBannedWords: [String] = []
    @State private var notMatchedWords: [String] = []
    @State private var transcription: String = ""
    let bannedWordsManager = BannedWordsManager()
    
    func speak(_ text: String) {
        let speechTools = AudioManager.shared.speechTools
        bannedWordsManager.check(text: text, settings: settings.first!, enabledLanguages: enabledLanguages, bannedWords: bannedWords, complete: ({ transcription, matchedBannedWords, notMatchedWords, voiceId in
            self.matchedBannedWords = matchedBannedWords
            self.transcription = transcription
            self.notMatchedWords = notMatchedWords
            
            DispatchQueue.main.async {
                let utterance = AVSpeechUtterance(string: text)
                utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
                speechTools.synthesizer.speak(utterance)
            }
        }))
    }
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            Text("Enter a phrase with some banned words, try misspellings, and see what happens\nAdd detected words\nUse * and ? as wildcards").padding(.horizontal, 20)
            HStack {
                TextField("Test phrase", text: $textForTesting)
                    .disableAutocorrection(true)
                    .padding(5)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                Button("Test") {
                    speak(textForTesting)
                }.buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            if !transcription.isEmpty {
                HStack{
                    Image(systemName: "ellipsis.bubble").resizable()
                        .frame(width: 32, height: 25)
                    Text(transcription)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                if !matchedBannedWords.isEmpty {
                    HStack{
                        Image(systemName: "speaker.slash.fill").resizable()
                            .frame(width: 32, height: 25)
                        Text("Will be muted, matches found\n⛔️\(matchedBannedWords.joined(separator: " ⛔️"))")
                    }.padding(.horizontal, 20).padding(.vertical, 10)
                } else {
                    HStack{
                        Image(systemName: "speaker.wave.2.fill").resizable()
                            .frame(width: 32, height: 25)
                        Text("Allowed")
                    }.padding(.horizontal, 20).padding(.vertical, 10)
                }
            }
            List(Array(notMatchedWords.enumerated()), id: \.offset) { index, word in
                HStack {
                    TextField("", text: $notMatchedWords[index])
                        .disableAutocorrection(true)
                        .padding(5)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.black)
                    Button("Add") {
                        modelContext.insert(BannedWord(notMatchedWords[index]))
                        try! modelContext.save()
                        speak(textForTesting)
                    }.buttonStyle(.bordered)
                }
            }
            Spacer()
        }
        .navigationTitle("Test Banned words")
    }
}

struct BannedWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @State private var speechRecognitionEnabled: Bool = false
    @State private var speechRecognitionDenied: Bool = false
    @State private var search: String = ""
    @State private var enabled: Bool = true

    let highlightColor = Color("itemHighlightColor")
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            if speechRecognitionDenied {
                Text("Mute words even if they are misspelled")
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                HStack{
                    HStack{
                            Text("This app uses reverse speech recognition to detect misspelled words, but it has been explicitly **DISABLED** in Settings\n\nPlease enable it in Settings → Privacy → Speech Recognition to use this feature")
                    }.padding(.all, 20)
                        .background(highlightColor)
                        .cornerRadius(15)
                }.padding(.horizontal, 20).padding(.bottom, 20).padding(.top, 5)
            } else if !speechRecognitionEnabled {
                Text("Mute words even if they are misspelled")
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                HStack{
                    VStack{
                            Text("This app uses reverse speech recognition to detect and mute banned words, even if they are misspelled")
                            Button("Enable Speech recognition") {
                                SFSpeechRecognizer.requestAuthorization { authStatus in
                                    speechRecognitionEnabled = authStatus == .authorized
                                    speechRecognitionDenied = authStatus == .denied
                                    enabled = speechRecognitionEnabled
                                }
                            }.buttonStyle(.bordered)
                    }.padding(.all, 20)
                        .background(highlightColor)
                        .cornerRadius(15)
                }.padding(.horizontal, 20).padding(.bottom, 20).padding(.top, 5)
            } else {
                Text("Mute words even if they are misspelled. This app uses reverse speech recognition to detect misspelled words\nUse * and ? as wildcards")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                Divider().padding(.horizontal, 20)
                HStack {
                    Text("Mute banned words")
                    Toggle("", isOn: $enabled)
                }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 5)
                HStack{
                    HStack {
                        NavigationLink(destination: TestBannedWordsView()) {
                            Text("Test that words muted")
                            Spacer()
                            Image(systemName: "questionmark.bubble").resizable()
                                .frame(width: 32, height: 32)
                            Image(systemName: "arrowshape.right.fill").resizable()
                                .frame(width: 32, height: 25)
                        }
                    }.padding(.vertical, 20)
                        .padding(.leading, 40)
                        .padding(.trailing, 10)
                        .background(highlightColor)
                        .cornerRadius(15)
                }.padding(.horizontal, 20).padding(.vertical, 5)
            }
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $search)
                    .disableAutocorrection(true)
                    .padding(5)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.black)
                Button("Add") {
                    if !search.isEmpty {
                        modelContext.insert(BannedWord(search))
                        try! modelContext.save()
                        search = ""
                    }
                }.buttonStyle(.borderedProminent)
            }.padding(.vertical, 5).padding(.horizontal, 10)
            FoundBannedWords(search: [search], showAll: search.isEmpty)
            Spacer()
        }
        .onAppear() {
            speechRecognitionEnabled = SFSpeechRecognizer.authorizationStatus() == .authorized
            speechRecognitionDenied = SFSpeechRecognizer.authorizationStatus() == .denied
            enabled = speechRecognitionEnabled && (settings.first!.bannedWordsEnabled ?? false)
        }
        .onDisappear() {
            self.settings.first!.bannedWordsEnabled = enabled
            try! modelContext.save()
        }
        .navigationTitle("Banned words")
    }
}
