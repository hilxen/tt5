//
//  NickView.swift
//  TT5
//
//  Created by Hilxen on 12/17/24.
//

import SwiftUI
import SwiftData
import AVFoundation


struct CustomRewardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query private var customRewards: [CustomReward]
    @State var customReward: CustomReward
    @State var name: String = ""
    @State var sound: Sound = Sound.Fanfare

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                TextField("Name", text: $name)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
            }.padding(.vertical, 5)
            HStack {
                Text("Sound").padding(.horizontal, 5)
                Spacer()
                Picker("Sound", selection: $sound) {
                    ForEach(Sound.allCases, id: \.self) {
                        Text($0.description())
                    }
                }
                Image(systemName: "play.circle")
                    .resizable().frame(width: 32, height: 32)
                    .onTapGesture { AudioServicesPlaySystemSound(SystemSoundID(sound.rawValue)) }
                .pickerStyle(.menu)
                .onChange(of: sound) {
                    AudioServicesPlaySystemSound(SystemSoundID(sound.rawValue))
                }
            }
            Spacer()

        }.onAppear {
            self.name = customReward.name
            self.sound = Sound.allCases.first(where: {$0.rawValue == customReward.sound}) ?? .Fanfare
        }.onDisappear {
            save()
        }
        .padding(20)
        .navigationTitle("Edit Custom Reward")
    }
    
    func save() {
        if let _customReward = customRewards.first(where: {$0.id == customReward.id}) {
            _customReward.set(name: name, sound: sound);
        } else {
            customReward.set(name: name, sound: sound);
            modelContext.insert(customReward)
        }
        try! modelContext.save()
    }
}
