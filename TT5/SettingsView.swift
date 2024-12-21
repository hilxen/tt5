//
//  SettingsView.swift
//  TT5
//
//  Created by Hilxen on 12/9/24.
//
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
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
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
            }.padding(.vertical, 10)
                .padding(.leading, 15)
                .padding(.trailing, 5)
            List {
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
                    NavigationLink(destination: NickListView()) {
                        Image(systemName: "person.3.sequence.fill")
                        Text("Customize Nicks")
                    }
                }.padding(.vertical, 5)
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
        try! modelContext.save()
    }
    
}
