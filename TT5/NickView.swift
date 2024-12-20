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
    let nick: Nick
    @State var muted: Bool = false
    @State var pronunciation: String = ""
    @State var overrideDefaults: Bool = false
    @State var volume: Volume = .normal
    @State var rate: Rate = .normal
    @State var pitch: Pitch = .normal
    @State var voice: Voice = .female

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
            }
            HStack {
                Image(systemName: "person.wave.2.fill")
                Text("Pronounce as")
                Spacer()
                TextField("Pronunciation", text: $pronunciation)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
            }.padding(.vertical, 5)
            HStack {
                Toggle("Override defaults", isOn: $overrideDefaults)
                    .padding(.trailing, 20)
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
                        ForEach(Voice.allCases, id: \.self) {
                            Text($0.description())
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
                    Picker("Rate", selection: $rate) {
                        ForEach(Rate.allCases, id: \.self) {
                            Text($0.description())
                        }
                    }
                    .pickerStyle(.menu)
                }
            }.disabled(!overrideDefaults).padding(.leading, 40)
            Spacer()

        }.onAppear {
            self.muted = nick.muted
            self.pronunciation = nick.pronunciation ?? ""
            self.overrideDefaults = !nick.defaults
            self.volume = Volume.allCases.first(where: {$0.rawValue == nick.volume}) ?? .normal
            self.rate = Rate.allCases.first(where: {$0.rawValue == nick.rate}) ?? .normal
            self.pitch = Pitch.allCases.first(where: {$0.rawValue == nick.pitch}) ?? .normal
            self.voice = Voice.allCases.first(where: {$0.rawValue == nick.voice}) ?? .female
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
                     rate: rate,
                     pitch: pitch,
                     volume: volume);
        } else {
            nick.set(overrideDefaults: overrideDefaults,
                     muted: muted,
                     pronunciation: pronunciation,
                     voice: voice,
                     rate: rate,
                     pitch: pitch,
                     volume: volume);
            modelContext.insert(nick)
        }
        try! modelContext.save()
    }
}
