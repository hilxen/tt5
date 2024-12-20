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
                Text("Channel")
                Spacer()
                TextField("Channel Name", text: $channel)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
            }.padding(.vertical, 5)
            HStack {
                Text("Volume")
                Spacer()
                Button {
                    if volume > minVolume {
                        volume -= 1
                    }
                } label: {
                    Image(systemName: "speaker.minus.fill")
                }
                Text("\(volume)").padding(.horizontal, 20)
                Button {
                    if volume < maxVolume {
                        volume += 1
                    }
                } label: {
                    Image(systemName: "speaker.plus.fill")
                }.padding(.trailing, 20)
            }.padding(.vertical, 5)
            HStack {
                Toggle("Muted", isOn: $muted)
                    .padding(.trailing, 20)
            }.padding(.vertical, 5)
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
            
            
            HStack {
                Button("Save") { save() }
            }.padding(.vertical, 5)
            Spacer()
        }.onAppear {
            channel = settings.first!.channel
            volume = settings.first!.volume
            muted = settings.first!.muted
            rate = Rate.allCases.first(where: {$0.rawValue == settings.first!.rate}) ?? .normal
            pitch = Pitch.allCases.first(where: {$0.rawValue == settings.first!.pitch}) ?? .normal
            voice = Voice.allCases.first(where: {$0.rawValue == settings.first!.voice}) ?? .female
        }.onDisappear {
            save()
        }
        .padding(20)
    }
    
    func save() {
        settings.first!.channel = channel
        settings.first!.volume = volume
        settings.first!.muted = muted
        self.settings.first!.rate = rate.rawValue
        self.settings.first!.pitch = pitch.rawValue
        self.settings.first!.voice = voice.rawValue 
        try! modelContext.save()
    }
    
}
