//
//  NickView.swift
//  TT5
//
//  Created by Hilxen on 12/17/24.
//

import SwiftUI
import SwiftData


struct NickView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query private var nicks: [Nick]
    @State var nick: Nick
    @State var muted: Bool = false
    @State var pronunciation: String = ""
    @State var overrideDefaults: Bool = false
    @State var volume: Volume = .normal
    @State var rateValue: Float = Rate.normal.rawValue
    @State var pitch: Pitch = .normal
    @State var voice: String = Voice.female.rawValue

    let minVolume: Int = 0
    let maxVolume: Int = 10
    

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Text(nick.name).bold().font(.title)
                Spacer()
            }.padding(.vertical, 5)
            HStack {
                Image(systemName: "speaker.slash.fill")
                Text("Muted")
                Spacer()
                Toggle("", isOn: $muted)
                    .padding(.trailing, 20)
                    .onChange(of: muted) {
                        if muted != settings.first!.muted {
                            overrideDefaults = true
                        }
                    }
            }
            HStack {
                Image(systemName: "person.wave.2.fill")
                Text("Pronounce as")
                Spacer()
                TextField("Pronunciation", text: $pronunciation)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
            }.padding(.vertical, 5)
            HStack {
                Toggle("Override defaults", isOn: $overrideDefaults)
                    .padding(.trailing, 20)
                    .onChange(of: overrideDefaults) {
                        if !overrideDefaults {
                            muted = settings.first!.muted
                        }
                    }
            }
            VStack {
                HStack {
                    Text("Volume")
                    Spacer()
                    Picker("Volume", selection: $volume) {
                        ForEach(Volume.allCases, id: \.self) {
                            Text($0.description())
                        }
                    }
                    .pickerStyle(.menu)
                }
                HStack {
                    Text("Voice")
                    Spacer()
                    Picker("Voice", selection: $voice) {
                        ForEach(AudioManager.shared.speechTools.allVoices(), id: \.self) {
                            Text($0.localizedCapitalized)
                        }
                    }
                    .pickerStyle(.menu)
                }
                HStack {
                    Text("Voice Pitch")
                    Spacer()
                    Picker("Pitch", selection: $pitch) {
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
            }.disabled(!overrideDefaults).padding(.leading, 40)
            Spacer()

        }.onAppear {
            self.muted = nick.defaults ? settings.first!.muted : nick.muted
            self.pronunciation = nick.pronunciation ?? ""
            self.overrideDefaults = !nick.defaults
            self.volume = Volume.allCases.first(where: {$0.rawValue == nick.volume}) ?? .normal
            self.rateValue = nick.rate ?? Rate.normal.rawValue
            self.pitch = Pitch.allCases.first(where: {$0.rawValue == nick.pitch}) ?? .normal
            self.voice = nick.voice ?? Voice.female.rawValue
        }.onDisappear {
            save()
        }
        .padding(20)
        .navigationTitle("Edit Nick")
    }
    
    func save() {
        if let _nick = nicks.first(where: {$0.name == nick.name}) {
            _nick.set(overrideDefaults: overrideDefaults,
                     muted: muted,
                     pronunciation: pronunciation,
                     voice: voice,
                     rateValue: rateValue,
                     pitch: pitch,
                     volume: volume);
        } else {
            nick.set(overrideDefaults: overrideDefaults,
                     muted: muted,
                     pronunciation: pronunciation,
                     voice: voice,
                     rateValue: rateValue,
                     pitch: pitch,
                     volume: volume);
            modelContext.insert(nick)
        }
        try! modelContext.save()
    }
}
