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
    @State private var defaultMuted: Bool = false
    let minVolume: Int = 1
    let maxVolume: Int = 10

    func save() {
        settings.first!.channel = channel
        settings.first!.volume = volume
        settings.first!.defaultMuted = defaultMuted
        try! modelContext.save()
    }
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Text("Join channel")
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
                Toggle("Muted", isOn: $defaultMuted)
                    .padding(.trailing, 20)
            }.padding(.vertical, 5)
            HStack {
                Button("Save") { save() }
            }.padding(.vertical, 5)
            Spacer()
        }.onAppear {
            channel = settings.first!.channel
            volume = settings.first!.volume
            defaultMuted = settings.first!.defaultMuted
        }.onDisappear {
            save()
        }
        .padding(20)
    }
}
