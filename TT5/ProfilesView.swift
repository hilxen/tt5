//
//  Config.swift
//  TT5
//
//  Created by Hilxen on 1/5/25.
//

import SwiftUI
import SwiftData

final class Profile: Codable {
    enum CodingKeys: CodingKey {
        case settings
        case languages
        case channels
        case nicks
        case bannedWords
        case customRewards
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settings = try container.decode([Settings].self, forKey: .settings)
        languages = try container.decode([Language].self, forKey: .languages)
        channels = try container.decode([Channel].self, forKey: .channels)
        nicks = try container.decode([Nick].self, forKey: .nicks)
        bannedWords = try container.decode([BannedWord].self, forKey: .bannedWords)
        customRewards = try container.decode([CustomReward].self, forKey: .customRewards)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(settings, forKey: .settings)
        try container.encode(languages, forKey: .languages)
        try container.encode(channels, forKey: .channels)
        try container.encode(nicks, forKey: .nicks)
        try container.encode(bannedWords, forKey: .bannedWords)
        try container.encode(customRewards, forKey: .customRewards)
    }
    
    init(settings: [Settings], languages: [Language], channels: [Channel], nicks: [Nick], bannedWords: [BannedWord], customRewards: [CustomReward]) {
        self.settings = settings
        self.languages = languages
        self.channels = channels
        self.nicks = nicks
        self.bannedWords = bannedWords
        self.customRewards = customRewards
    }
    
    var settings: [Settings]
    var languages: [Language]
    var channels: [Channel]
    var nicks: [Nick]
    var bannedWords: [BannedWord]
    var customRewards: [CustomReward]
}


extension URL: Identifiable {
    public var id: String { self.absoluteString }
}


struct ProfilesView: View {
    @Environment(\.presentationMode) var presentation
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query private var languages: [Language]
    @Query private var channels: [Channel]
    @Query private var nicks: [Nick]
    @Query private var bannedWords: [BannedWord]
    @Query private var customRewards: [CustomReward]
    
    @State private var name: String = "default"
    @State private var multiSelection = Set<String>()
    @State private var profiles: [URL] = []
    @State private var actionFeedback = false
    let itemHighlightColor = Color(red: 231/255, green: 211/255, blue: 253/255)
    let itemSelectColor = Color(red: 210/255, green: 208/255, blue: 214/255)
    
    func reloadProfiles() {
        profiles.removeAll()
        profiles.append(contentsOf: contents())
    }
    
    func save() {
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent(name).appendingPathExtension("json")
        let jsonEncoder = JSONEncoder()
        let profile = Profile(settings: settings, languages: languages, channels: channels, nicks: nicks, bannedWords: bannedWords, customRewards: customRewards)
        let json = String(data: try! jsonEncoder.encode(profile), encoding: String.Encoding.utf8)!
        try! json.write(to: fileURL, atomically: true, encoding: .utf8)
        reloadProfiles()
    }
    
    func load(url: URL) {
        let data = try! Data(contentsOf: url)
        let profile = try! JSONDecoder().decode(Profile.self, from: data)

        settings.first!.set(profile.settings.first!)
        
        try! modelContext.delete(model: Nick.self)
        for nick in profile.nicks {
            modelContext.insert(nick)
        }
        
        try! modelContext.delete(model: Language.self)
        for language in profile.languages {
            modelContext.insert(language)
        }
        
        try! modelContext.delete(model: Channel.self)
        for channel in profile.channels {
            modelContext.insert(channel)
        }

        try! modelContext.delete(model: BannedWord.self)
        for bannedWord in profile.bannedWords {
            modelContext.insert(bannedWord)
        }

        try! modelContext.delete(model: CustomReward.self)
        for customReward in profile.customRewards {
            modelContext.insert(customReward)
        }
        
        try! modelContext.save()
    }
    
    func contents() -> [URL] {
        let documentDirectory = try! FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        var result = [URL]()
        let properties = [URLResourceKey.nameKey, URLResourceKey.contentModificationDateKey]

        let directoryContents = try! FileManager.default.contentsOfDirectory(
                at: documentDirectory,
                includingPropertiesForKeys: properties,
                options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles
        )
        for url in directoryContents {
            if url.lastPathComponent.hasSuffix(".json") {
                result.append(url)
            }
        }
        return result
    }
    
    func delete(_ url: URL) {
        try! FileManager.default.removeItem(at: url)
        reloadProfiles()
    }
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            HStack{
                Text("Save and load settings to")
                Button("Files") {
                    let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
                        if UIApplication.shared.canOpenURL(sharedUrl) {
                            UIApplication.shared.open(sharedUrl, options: [:])
                        }
                    }
                }.buttonStyle(.bordered)
            }.padding(.horizontal, 20)
            HStack {
                TextField("Profile Name", text: $name)
                    .disableAutocorrection(true)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .border(name.isEmpty ? Color.red : Color.gray, width: 1)
                Button("Save") {
                    withAnimation(.linear(duration: 1)) {
                        actionFeedback = true
                        save()
                    } completion: {
                        withAnimation {
                            actionFeedback = false
                        }
                    }
                }.buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            HStack {
                List(profiles, selection: $multiSelection) { url in
                    let itemName = url.deletingPathExtension().lastPathComponent
                    HStack {
                        Text(itemName).background(name == itemName && actionFeedback ? itemHighlightColor: Color.clear)
                    }
                    .listRowBackground(name == itemName && actionFeedback ? itemHighlightColor: (multiSelection.contains(url.id) ? itemSelectColor: Color.white))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            delete(url)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }.swipeActions(edge: .leading) {
                        Button() {
                            print("Selected \(url.lastPathComponent)")
                        } label: {
                            Label("Select", systemImage: "checkmark.circle.fill")
                        }.tint(.blue)
                    }
                }
            }
            Spacer()
        }
        .onAppear() {
            reloadProfiles()
        }
        .navigationTitle("Profiles")
        if !multiSelection.isEmpty {
            HStack {
                if multiSelection.count == 1 {
                    Button() {
                        load(url: URL(string: multiSelection.first!)!)
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Label("Load", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
                Button(role: .destructive) {
                    for url in multiSelection {
                        delete(URL(string: url)!)
                    }
                    multiSelection.removeAll()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                
            }.padding(.horizontal, 20)
        }
    }
}
