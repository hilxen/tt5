//
//  LanguagesView.swift
//  TT5
//
//  Created by Hilxen on 12/21/24.
//
import SwiftUI
import SwiftData
import NaturalLanguage
import AVFoundation

func voiceName(_ id: String) -> String {
    let name = id.components(separatedBy: ".").last! + (id.contains("enhanced") ? " (enhanced)" : "")
    if name.starts(with: "siri_") {
        return name.components(separatedBy: "_")[1]
    } else {
        return name
    }
}

func genderToSting(_ gender: AVSpeechSynthesisVoiceGender) -> String {
    switch gender {
    case .female: return "female"
    case .male: return "male"
    default: return "unknown"
    }
}


struct VoiceIdsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    let language: Language
    let synthesizer = AVSpeechSynthesizer()
    @State var sampleText: String = "Testing the voice"
    
    func playSample(voiceId: VoiceId) {
        AudioManager.shared.announce(settings: settings.first!, text: sampleText, voiceId: voiceId.id)
    }
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                TextField("Sample text", text: $sampleText)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
            }.padding(.vertical, 10)
                .padding(.leading, 15)
                .padding(.trailing, 5)
            List(language.voiceIds) { voiceId in
                HStack {
                    Text(voiceId.gender == "female"
                          ? "F" : voiceId.gender == "male"
                          ? "M" : "X"
                    )
                    Text(voiceName(voiceId.id))
                    Image(systemName: "play.circle")
                        .resizable().frame(width: 32, height: 32)
                        .onTapGesture { playSample(voiceId: voiceId) }
                    Spacer()
                    Button {
                        if language.femaleVoiceId != voiceId.id && language.maleVoiceId != voiceId.id {
                            if language.maleVoiceId == nil && language.femaleVoiceId == nil {
                                language.femaleVoiceId = voiceId.id
                            } else if language.maleVoiceId == nil {
                                language.maleVoiceId = voiceId.id
                            } else {
                                language.femaleVoiceId = voiceId.id
                            }
                        } else if language.femaleVoiceId == voiceId.id {
                            language.femaleVoiceId = nil
                            if language.maleVoiceId == nil {
                                language.maleVoiceId = voiceId.id
                            }
                        } else if language.maleVoiceId == voiceId.id {
                            language.maleVoiceId = nil
                            if language.femaleVoiceId == nil {
                                language.femaleVoiceId = voiceId.id
                            }
                        }
                    } label: {
                        Text(language.femaleVoiceId == voiceId.id
                              ? "✅F" : language.maleVoiceId == voiceId.id
                              ? "✅M" : "")
                    }
                }
            }
        }.navigationTitle(language.displayName())
    }
}


struct LanguagesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Language.name) private var languages: [Language]
    @State private var searchText: String = ""

    var filteredLanguages: [Language] {
        guard !searchText.isEmpty else { return languages }
        return languages.filter { $0.displayName().localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text("Tip: for best experience select only one or two languages to enable voice synthesis")
                .padding(.horizontal, 20)
            List(filteredLanguages) {language in
                VStack{
                    HStack{
                        Text(language.displayName())
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { return language.enabled },
                            set: { (newValue) in
                                if let l = languages.first(where: {
                                    $0.enabled && $0.languageCode() == language.languageCode()}) {
                                    l.enabled = false
                                }
                                return language.enabled = newValue}
                        )).frame(width: 60)
                    }
                    NavigationLink(destination: VoiceIdsView(language: language)) {
                        HStack{
                            if language.femaleVoiceId != nil {
                                Text("F")
                                Text(voiceName(language.femaleVoiceId!))
                            }
                            if language.maleVoiceId != nil {
                                Text("M")
                                Text(voiceName(language.maleVoiceId!))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Languages")
        .searchable(text: $searchText, prompt: "Search languages")
    }
}
