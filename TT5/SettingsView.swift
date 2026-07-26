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

func normalizeChannelName(_ channel: String) -> String {
    return channel.components(separatedBy: "/").last!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
}


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
    @State private var bannedWordsEnabled: Bool = false
    @State private var subscribers: Bool = true
    @State private var broadcaster: Bool = true
    @State private var highlighted: Bool = true
    @State private var customRewards: Bool = true
    @State private var muteConversations: Bool = false
    @State private var showStreamPreview: Bool = true
    @State var rateValue: Float = Rate.normal.rawValue
    @State var pitch: Pitch = .normal
    @State var voice: String = Voice.female.rawValue
    @State private var overrideForConversations: Bool = false
    @State private var volumeForConversations: Int = 0
    @State var rateValueForConversations: Float = Rate.normal.rawValue
    @State var pitchForConversations: Pitch = .normal
    @State var voiceForConversations: String = Voice.female.rawValue

    @State private var showHelp = false
    @State var enabledLanguages: [Language] = []
    @Binding var forceShowSettings: Bool
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
                    .foregroundColor(.primary)
                    .border(channel.isEmpty ? Color.red : Color.gray, width: 1)
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
                    Image(systemName: "speaker.wave.3.fill").padding(.trailing, 1)
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
                    NavigationLink(destination: BannedWordsView()) {
                        Image(systemName: "exclamationmark.bubble.fill").padding(.trailing, 8)
                        Text("Banned Words")
                    }
                }.padding(.vertical, 5)
                Toggle(isOn: $muteConversations) {
                    Label("Mute conversations", systemImage: "person.2.slash.fill")
                }
                Toggle(isOn: $overrideForConversations) {
                    Label("Customize Conversations", systemImage: "person.2.badge.gearshape.fill").bold()
                }
                if overrideForConversations {
                    VStack {
                        HStack {
                            Text("Speech Volume")
                            Spacer()
                            Image(systemName: "speaker.minus.fill").onTapGesture {
                                if volumeForConversations > minVolume {
                                    volumeForConversations -= 1
                                }
                            }
                            Text("\(volumeForConversations)").padding(.horizontal, 20)
                            Image(systemName: "speaker.plus.fill").onTapGesture {
                                if volumeForConversations < maxVolume {
                                    volumeForConversations += 1
                                }
                            }
                        }.padding(.vertical, 5)
                        HStack {
                            Text("Voice")
                            Spacer()
                            Picker("", selection: $voiceForConversations) {
                                ForEach(AudioManager.shared.speechTools.allVoices(), id: \.self) {
                                    Text($0.localizedCapitalized)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        HStack {
                            Text("Voice Pitch")
                            Spacer()
                            Picker("", selection: $pitchForConversations) {
                                ForEach(Pitch.allCases, id: \.self) {
                                    Text($0.description())
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        HStack {
                            Text("Speech Rate")
                            Spacer()
                            Slider(
                                value: $rateValueForConversations,
                                in: Rate.min.rawValue...Rate.max.rawValue,
                                step: Rate.step
                            )
                        }
                    }.padding(.leading, 20)
                }
                Toggle(isOn: $muted) {
                    Label("All muted", systemImage: "speaker.slash.fill")
                }
                HStack {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                    Image(systemName: "speaker")
                    Text("Exceptions").bold()
                }.padding(.vertical, 5)
                VStack {
                    Toggle(isOn: $mods) {
                        HStack {
                            Image("mod").resizable().scaledToFit().frame(height: 20)
                            Text("Moderators")
                        }
                    }
                    Toggle(isOn: $vips) {
                        HStack {
                            Image("vip").resizable().scaledToFit().frame(height: 20)
                            Text("VIPs")
                        }
                    }
                    Toggle(isOn: $subscribers) {
                        HStack {
                            Image("sub").resizable().scaledToFit().frame(height: 20)
                            Text("Subscribers")
                        }
                    }
                    Toggle(isOn: $broadcaster) {
                        HStack {
                            Image("own").resizable().scaledToFit().frame(height: 20)
                            Text("Channel owner")
                        }
                    }
                    Toggle(isOn: $highlighted) {
                        HStack {
                            Image(systemName: "highlighter").resizable().scaledToFit().frame(height: 20)
                            Text("Highlighted text")
                        }
                    }
                    Toggle(isOn: $customRewards) {
                        HStack {
                            Image("reward").resizable().scaledToFit().frame(height: 20)
                            Text("Custom rewards")
                        }
                    }
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
                            ForEach(AudioManager.shared.speechTools.allVoices(), id: \.self) {
                                Text($0.localizedCapitalized)
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
                        Slider(
                            value: $rateValue,
                            in: Rate.min.rawValue...Rate.max.rawValue,
                            step: Rate.step
                        )
                    }
                }.padding(.leading, 20)
                HStack {
                    NavigationLink(destination: NickListView()) {
                        Image(systemName: "person.3.sequence.fill")
                        Text("Customize Nicks")
                    }
                }.padding(.vertical, 5)
                HStack {
                    NavigationLink(destination: CustomRewardListView()) {
                        Image(systemName: "gift")
                        Text("Custom Rewards").padding(.leading, 20)
                    }
                }.padding(.vertical, 5)
                Toggle(isOn: $showStreamPreview) {
                    Label("Show stream preview", systemImage: "play.rectangle")
                }
                HStack {
                    NavigationLink(destination: ProfilesView()) {
                        Image(systemName: "folder.badge.gearshape")
                        Text("Profiles").padding(.leading, 15)
                    }
                }.padding(.vertical, 5)
                HStack {
                    NavigationLink(destination: LogView()) {
                        Image(systemName: "list.bullet.clipboard")
                        Text("Log").padding(.leading, 20)
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
            rateValue = settings.first!.rate
            pitch = Pitch.allCases.first(where: {$0.rawValue == settings.first!.pitch}) ?? .normal
            voice = settings.first!.voice
            mods = settings.first!.mods
            vips = settings.first!.vips
            subscribers = settings.first!.subscribers
            broadcaster = settings.first!.broadcaster
            highlighted = settings.first!.highlighted
            customRewards = settings.first!.customRewards ?? true
            muteConversations = settings.first!.muteConversations ?? false
            showStreamPreview = settings.first!.showStreamPreview ?? true
            overrideForConversations = settings.first!.overrideForConversations ?? false
            volumeForConversations = settings.first!.volumeForConversations ?? volume
            rateValueForConversations = settings.first!.rateForConversations ?? rateValue
            pitchForConversations = Pitch.allCases.first(where: {$0.rawValue == settings.first!.pitchForConversations}) ?? pitch
            voiceForConversations = settings.first!.voiceForConversations ?? voice
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
        settings.first!.volume = volume
        settings.first!.muted = muted
        self.settings.first!.rate = rateValue
        self.settings.first!.pitch = pitch.rawValue
        self.settings.first!.voice = voice
        self.settings.first!.mods = mods
        self.settings.first!.vips = vips
        self.settings.first!.subscribers = subscribers
        self.settings.first!.broadcaster = broadcaster
        self.settings.first!.highlighted = highlighted
        self.settings.first!.customRewards = customRewards
        self.settings.first!.muteConversations = muteConversations
        self.settings.first!.showStreamPreview = showStreamPreview
        self.settings.first!.overrideForConversations = overrideForConversations
        self.settings.first!.volumeForConversations = volumeForConversations
        self.settings.first!.rateForConversations = rateValueForConversations
        self.settings.first!.pitchForConversations = pitchForConversations.rawValue
        self.settings.first!.voiceForConversations = voiceForConversations
        let normalizedChannel = normalizeChannelName(channel)
        if !normalizedChannel.isEmpty && !channels.contains(where: {$0.name == normalizedChannel}) {
            modelContext.insert(Channel(name: normalizedChannel))
        }
        channel = normalizedChannel
        settings.first!.channel = channel
        forceShowSettings = channel.isEmpty
        try! modelContext.save()
        presentation.wrappedValue.dismiss()
    }
    
    func initLanguages() {
        let voices = AVSpeechSynthesisVoice.speechVoices() //list of supported voices
        var added: [String: Language] = [:]
        enabledLanguages.removeAll()
        for voice in voices {
            //print(voice.language, voice.name, voice.identifier, voice.gender)
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
        let availableIDs = Set(voices.map { $0.identifier })
        for language in languages {
            language.voiceIds.removeAll { voiceId in
                !availableIDs.contains(voiceId.id)
            }
        }
        if enabledLanguages.isEmpty {
            let defaultLanuage = "en-US"
            let language = languages.first(where: {$0.name == defaultLanuage}) ?? added[defaultLanuage]!
            language.enabled = true
            enabledLanguages.append(language)
        }
        try! modelContext.save()
    }
}

