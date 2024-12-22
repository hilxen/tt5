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
    let name = id.components(separatedBy: ".").last!
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
    let language: Language
    let synthesizer = AVSpeechSynthesizer()
    static let shared = AudioManager()
    var session = AVAudioSession.sharedInstance()
    @State var sampleText: String = "Testing the voice"
    
    private func activateSession() {
        try? session.setCategory(
            .playback,
            mode: .default,
            options: [.duckOthers]
        )
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        try? session.overrideOutputAudioPort(.speaker)
    }

    
    func playSample(voiceId: VoiceId) {
        activateSession()
        print(playSample, voiceId)
        let voice = AVSpeechSynthesisVoice(identifier: voiceId.id)
        let utterance = AVSpeechUtterance(string: sampleText)
        utterance.voice = voice
        synthesizer.speak(utterance)
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
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
            }.padding(.vertical, 10)
                .padding(.leading, 15)
                .padding(.trailing, 5)
            List(language.voiceIds) { voiceId in
                HStack {
                    Image(systemName: voiceId.gender == "female"
                          ? "figure.stand.dress" : voiceId.gender == "male"
                          ? "figure.stand" : "figure.stand.dress.line.vertical.figure"
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
                        Image(systemName: language.femaleVoiceId == voiceId.id
                              ? "figure.stand.dress" : language.maleVoiceId == voiceId.id
                              ? "figure.stand" : "viewfinder").resizable().frame(width: 32, height: 32)
                    }
                }
            }
        }.navigationTitle(Locale.current.localizedString(forIdentifier: language.name)!)
    }
}


struct LanguagesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Language.name) private var languages: [Language]
    
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text("Tip: for best experience select only one or two languages to enable voice synthesis")
                .padding(.horizontal, 20)
            List(languages) {language in
                VStack{
                    HStack{
                        Text(Locale.current.localizedString(forIdentifier: language.name)!)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { return language.enabled },
                            set: { (newValue) in
                                if let l = languages.first(where: {
                                    $0.enabled && $0.name.components(separatedBy: "-")[0] == language.name.components(separatedBy: "-")[0]}) {
                                    l.enabled = false
                                }
                                return language.enabled = newValue}
                        )).frame(width: 60)
                    }
                    NavigationLink(destination: VoiceIdsView(language: language)) {
                        HStack{
                            if language.femaleVoiceId != nil {
                                Image(systemName: "figure.stand.dress")
                                Text(voiceName(language.femaleVoiceId!))
                            }
                            if language.maleVoiceId != nil {
                                Image(systemName: "figure.stand")
                                Text(voiceName(language.maleVoiceId!))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Languages")
    }
}
