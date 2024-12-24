//
//  SettingsView.swift
//  TT5
//
//  Created by Hilxen on 12/9/24.
//
import SwiftUI
import SwiftData
import NaturalLanguage
import AVFoundation



struct SettingsView: View {
    @Environment(\.presentationMode) var presentation
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query private var languages: [Language]
    @Query private var channels: [Channel]
    @State private var volume: Int = 0
    @State private var channel: String = ""
    @State private var muted: Bool = false
    @State private var mods: Bool = true
    @State private var vips: Bool = true
    @State private var subscribers: Bool = true
    @State private var broadcaster: Bool = true
    @State private var highlighted: Bool = true
    @State var rate: Rate = .normal
    @State var pitch: Pitch = .normal
    @State var voice: Voice = .female
    @State private var showHelp = false
    @State var enabledLanguages: [Language] = []
    let minVolume: Int = 0
    let maxVolume: Int = 10
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            HStack {
                Image(systemName: "video.fill").padding(.trailing, 5)
                Text("Channel")
                Spacer()
                TextField("Channel Name", text: $channel)
                    .disableAutocorrection(true)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                NavigationLink(destination: ChannelsListView()) {
                    Image(systemName: "folder")
                        .resizable()
                        .frame(width: 32, height: 25)
                        .padding(.trailing, 10)
                }
            }.padding(.vertical, 10)
                .padding(.leading, 15)
                .padding(.trailing, 5)
            List {
                HStack(alignment: .top) {
                    NavigationLink(destination: LanguagesView()) {
                        Image(systemName: "person.2.wave.2.fill")
                        VStack (alignment: .leading) {
                            ForEach(enabledLanguages) { language in
                                Text(language.displayName())
                            }
                        }.padding(.leading, 0)
                    }
                }.padding(.vertical, 5)
                HStack {
                    Image(systemName: "speaker.wave.3.fill")
                    Text("Speech Volume")
                    Spacer()
                    Image(systemName: "speaker.minus.fill").onTapGesture {
                        if volume > minVolume {
                            volume -= 1
                        }
                    }
                    Text("\(volume)").padding(.horizontal, 20)
                    Image(systemName: "speaker.plus.fill").onTapGesture {
                        if volume < maxVolume {
                            volume += 1
                        }
                    }
                }.padding(.vertical, 5)
                HStack {
                    Image(systemName: "speaker.slash.fill").padding(.leading, 2).padding(.trailing, 8)
                    Text("All muted")
                    Spacer()
                    Toggle("", isOn: $muted)
                }.padding(.vertical, 5)
                HStack {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                    Image(systemName: "speaker")
                    Text("Exceptions").bold()
                }.padding(.vertical, 5)
                VStack {
                    HStack {
                        Image("mod").resizable().scaledToFit().frame(height: 20)
                        Text("Moderators")
                        Spacer()
                        Toggle("", isOn: $mods)
                    }.padding(.bottom, 5)
                    HStack {
                        Image("vip").resizable().scaledToFit().frame(height: 20)
                        Text("VIPs")
                        Spacer()
                        Toggle("", isOn: $vips)
                    }.padding(.bottom, 5)
                    HStack {
                        Image("sub").resizable().scaledToFit().frame(height: 20)
                        Text("Subscribers")
                        Spacer()
                        Toggle("", isOn: $subscribers)
                    }.padding(.bottom, 5)
                    HStack {
                        Image("own").resizable().scaledToFit().frame(height: 20)
                        Text("Channel owner")
                        Spacer()
                        Toggle("", isOn: $broadcaster)
                    }.padding(.bottom, 5)
                    HStack {
                        Image(systemName: "highlighter").resizable().scaledToFit().frame(height: 20)
                        Text("Highlighted text")
                        Spacer()
                        Toggle("", isOn: $highlighted)
                    }.padding(.bottom, 5)
                }.padding(.leading, 25)
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Default settings for all nicks").bold()
                }.padding(.vertical, 5)
                VStack {
                    HStack {
                        Text("Voice")
                        Spacer()
                        Picker("", selection: $voice) {
                            ForEach(Voice.allCases, id: \.self) {
                                Text($0.description())
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    HStack {
                        Text("Voice Pitch")
                        Spacer()
                        Picker("", selection: $pitch) {
                            ForEach(Pitch.allCases, id: \.self) {
                                Text($0.description())
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    HStack {
                        Text("Speech Rate")
                        Spacer()
                        Picker("", selection: $rate) {
                            ForEach(Rate.allCases, id: \.self) {
                                Text($0.description())
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }.padding(.leading, 20)
                HStack {
                    NavigationLink(destination: NickListView()) {
                        Image(systemName: "person.3.sequence.fill")
                        Text("Customize Nicks")
                    }
                }.padding(.vertical, 5)
            }.listStyle(PlainListStyle())
            HStack {
                Button("Save") {
                    save()
                }.buttonStyle(.borderedProminent)
            }.padding(.all, 20)
            Spacer()
        }.onAppear {
            channel = settings.first!.channel
            volume = settings.first!.volume
            muted = settings.first!.muted
            rate = Rate.allCases.first(where: {$0.rawValue == settings.first!.rate}) ?? .normal
            pitch = Pitch.allCases.first(where: {$0.rawValue == settings.first!.pitch}) ?? .normal
            voice = Voice.allCases.first(where: {$0.rawValue == settings.first!.voice}) ?? .female
            mods = settings.first!.mods
            vips = settings.first!.vips
            subscribers = settings.first!.subscribers
            broadcaster = settings.first!.broadcaster
            highlighted = settings.first!.highlighted
            initLanguages()
        }.onDisappear {
            save()
        }
        .navigationTitle("Settings")
        .toolbar {
            Button {
                showHelp = true
            } label: {
                Image(systemName: "questionmark.circle.fill")
            }
        }.navigationDestination(isPresented: $showHelp) {
            HelpView()
        }
    }
    
    func save() {
        settings.first!.channel = channel
        settings.first!.volume = volume
        settings.first!.muted = muted
        self.settings.first!.rate = rate.rawValue
        self.settings.first!.pitch = pitch.rawValue
        self.settings.first!.voice = voice.rawValue
        self.settings.first!.mods = mods
        self.settings.first!.vips = vips
        self.settings.first!.subscribers = subscribers
        self.settings.first!.broadcaster = broadcaster
        self.settings.first!.highlighted = highlighted
        let normalizedChannel = channel.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedChannel.isEmpty && !channels.contains(where: {$0.name == normalizedChannel}) {
            modelContext.insert(Channel(name: normalizedChannel))
        }
        try! modelContext.save()
        presentation.wrappedValue.dismiss()
    }
    
    func initLanguages() {
        let voices = AVSpeechSynthesisVoice.speechVoices() //list of supported voices
        var added: [String: Language] = [:]
        enabledLanguages.removeAll()
        for voice in voices {
            var language = languages.first(where: {$0.name == voice.language}) ?? added[voice.language]
            let found: Bool = language != nil
            if !found {
                language = Language(name: voice.language, enabled: false)
                added[voice.language] = language
            }
            if !language!.voiceIds.contains(where: {$0.id == voice.identifier}) {
                language!.voiceIds.append(VoiceId(id: voice.identifier, gender: genderToSting(voice.gender)))
            }
            if language!.femaleVoiceId == nil && voice.gender == .female {
                language!.femaleVoiceId = voice.identifier
            }
            if language!.maleVoiceId == nil && voice.gender == .male {
                language!.maleVoiceId = voice.identifier
            }
            if !found {
                modelContext.insert(Language(name: voice.language, enabled: false))
            }
            if language!.enabled && !enabledLanguages.contains(where: {$0.name == language!.name}) {
                enabledLanguages.append(language!)
            }
        }
        if enabledLanguages.isEmpty {
            let defaultLanuage = "en-US"
            var language = languages.first(where: {$0.name == defaultLanuage}) ?? added[defaultLanuage]!
            language.enabled = true
            enabledLanguages.append(language)
        }
        try! modelContext.save()
    }
}

