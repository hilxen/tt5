//
//  ContentView.swift
//  TT5
//
//  Created by Hilxen on 12/1/24.
//

import SwiftUI
import SwiftData
import TwitchIRC
import PopupView
import SwipeActions
import Combine
import NaturalLanguage
import AVFoundation
import CoreFoundation


class Model: ObservableObject {
    @Published var list = [Item]()
    @Published var newNicks = [String: Nick]()
    @Published var shouldRefresh = CurrentValueSubject<Bool, Never>(false)
    @Published var shouldMute = CurrentValueSubject<Bool, Never>(false)
    @Published var speakerItem: Item?
    @Published var speakerActive: Bool = false
    @Published var speakerCountdown: Int = -1
    @Published var lastHeartbeat: Int = Int(CFAbsoluteTimeGetCurrent())
}

struct ContentView: View, TwitchIRCDelegate, AudioManagerDelegate {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query private var nicks: [Nick]
    @Query(filter: #Predicate<Language> { $0.enabled }) private var enabledLanguages: [Language]
    @Query private var bannedWords: [BannedWord]

    @State private var showSettings = false
    @State private var showHelp = false
    @State private var firstLaunch = false
    @State private var forceShowSettings = false
    @State private var scale = 18.0
    @State private var vibrate: Bool = false
    @State private var previousChannel: String = ""
    
    @ObservedObject private var model = Model()
    let twitchIRC = TwitchIRC()
    let audioManager: AudioManager = AudioManager.shared
    let maxMessages: Int = 20
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let itemHighlightColor = Color(red: 231/255, green: 211/255, blue: 253/255)
    let itemAttentionColor = Color(red: 255/255, green: 200/255, blue: 200/255)
    let itemSelectedColor = Color(red: 255/255, green: 255/255, blue: 117/255)

    init() {
        twitchIRC.delegate = self
        audioManager.delegate = self
    }
    
    func initSettings() {
        if settings.isEmpty {
            modelContext.insert(Settings(channel: "", volume: 1, muted: false, rate: .normal, pitch: .normal, voice: .female, mods: true, vips: true, subscribers: true, broadcaster: true, highlighted: true, bannedWordsEnabled: false))
            try! modelContext.save()
        }
    }

    
    func onAppear() {
        print("****** ContentView: onAppear ******")
        initSettings()
        
        let _settings = settings.first!
        if (_settings.version ?? "") != getAppVersion() {
            firstLaunch = true
        } else if _settings.channel.isEmpty {
            forceShowSettings = true
        }
        audioManager.speechTools.recognizer.languageConstraints = enabledLanguages.map({NLLanguage($0.languageCode())})
        var enabledVoices = [String: [String: String]]()
        for language in enabledLanguages {
            enabledVoices[language.languageCode()] = [
                "female": language.femaleVoiceId ?? language.maleVoiceId!,
                "male": language.maleVoiceId ?? language.femaleVoiceId!
            ]
        }
        audioManager.speechTools.voices = enabledVoices
        checkNeedRefresh()
    }
    
    func checkNeedRefresh() {
        let _settings = settings.first!
        twitchIRC.connect()
        if twitchIRC.channel != _settings.channel {
            twitchIRC.join(channel: _settings.channel)
        }
        if previousChannel != settings.first!.channel {
            model.shouldRefresh.send(true)
            previousChannel = settings.first!.channel
            model.list.removeAll()
        }
    }
    
    func onDisappear() {
        print("****** ContentView: onDisappear ******")
    }
    
    func didBecomeActiveNotification() {
        print("****** ContentView: didBecomeActiveNotification ******")
        initSettings()
        let _settings = settings.first!
        twitchIRC.disconnect()
        twitchIRC.channel = _settings.channel
        twitchIRC.connect()
    }
    
    func didEnterBackgroundNotification() {
        print("****** ContentView: didEnterBackgroundNotification ******")
        // twitchIRC.disconnect()
    }
    
    
    func onMessage(pm: PrivateMessage) {
        DispatchQueue.main.async {
            let nick = getNick(name: pm.userLogin)
            nick.color = pm.color
            nick.vip = pm.isVIP
            nick.subscriber = pm.isSubscriber
            nick.mod = pm.isMod
            nick.broadcaster = pm.isBroadcaster
            print("addItem model.list.count=\(model.list.count)")
            let item = Item(id: pm.id, nick: nick, message: pm.message, messageId: pm.messageId, emotes: pm.emotes)
            model.list.append(item)
            if model.list.count > maxMessages {
                model.list.removeFirst()
            }
            let copyOfSettings = Settings(settings.first!)
            audioManager.textToSpeech(
                settings: copyOfSettings, nicks: nicks, item: item,
                bannedWords: bannedWords,
                enabledLanguages: enabledLanguages)
        }
    }
    
    func onNotification(text: String) {
    }
    
    func heartbeat() {
        DispatchQueue.main.async {
            let currentTime = Int(CFAbsoluteTimeGetCurrent())
            model.lastHeartbeat = currentTime
        }
    }
    
    func checkHeartbeat() {
        let currentTime = Int(CFAbsoluteTimeGetCurrent())
        if currentTime - model.lastHeartbeat > 60 {
            model.lastHeartbeat = currentTime
            print("****** Reconnnecting...")
            twitchIRC.disconnect()
        }
        checkNeedRefresh()
    }
    
    func speechStarted(item: Item) {
        model.speakerItem = item
        model.speakerActive = true
        model.speakerCountdown = -1
    }
    
    func speechFinished(item: Item) {
        model.speakerCountdown = 2
    }
    
    func getNick(name: String) -> Nick {
        print("get nick \(name)")
        let _settings = settings.first!
        if let nick = nicks.first(where: {$0.name == name}) ?? model.newNicks[name] {
            if nick.defaults {
                nick.muted = _settings.muted
                nick.volume = Volume.normal.rawValue
                nick.rate = _settings.rate
                nick.pitch = _settings.pitch
                nick.voice = _settings.voice
            } else {
                nick.volume = nick.volume ?? Volume.normal.rawValue
                nick.rate = nick.rate ?? _settings.rate
                nick.pitch = nick.pitch ?? _settings.pitch
                nick.voice = nick.voice ?? _settings.voice
            }
            return nick
        } else {
            let nick = Nick(name: name, muted: _settings.muted)
            nick.volume = Volume.normal.rawValue
            nick.rate = _settings.rate
            nick.pitch = _settings.pitch
            nick.voice = _settings.voice
            model.newNicks[name] = Nick(name: name, muted: _settings.muted)
            return nick
        }
    }
    
    func saveNewNicks() {
        for nick in model.newNicks.values {
            modelContext.insert(nick)
            print("Saved new nick", nick.name)
        }
        model.newNicks.removeAll()
    }
    
    func itemActive(_ item: Item) -> Bool {
       return model.speakerActive && item == model.speakerItem
    }

    func getIcons(_ item: Item) -> [String] {
        let mutedIcon = (item.nick.muted != settings.first!.muted) ? (item.nick.muted ? "speaker.slash": "speaker") : ""
        let soundIcon = (mutedIcon == "speaker.slash") ? mutedIcon : item.skipped ? "play.slash": mutedIcon

        var icons: [String] = []
        if !soundIcon.isEmpty {
            icons.append(soundIcon)
        }
        if item.nick.mod ?? false {
            icons.append("mod")
        }
        if item.nick.subscriber ?? false {
            icons.append("sub")
        }
        if item.nick.vip ?? false {
            icons.append("vip")
        }
        if item.nick.broadcaster ?? false {
            icons.append("own")
        }
        return icons
    }
    
        
    var body: some View {
        NavigationStack() {
            if firstLaunch {
                FirstLaunchHelpView(firstLaunch: $firstLaunch)
            } else if forceShowSettings {
                SettingsView(forceShowSettings: $forceShowSettings)
            } else {
                if !settings.isEmpty && !settings.first!.channel.isEmpty {
                    TwitchPlayerWebView(shouldRefresh: model.shouldRefresh, shouldMute: model.shouldMute)
                        .frame(height: 200)
                        .padding([.all], 5)
                }
                ScrollViewReader { scrollView in
                    ScrollView(.vertical) {
                        LazyVStack {
                            // Array(model.list.enumerated()), id: \.offset) is needed for auto scroll
                            ForEach(Array(model.list.enumerated()), id: \.offset) { index, item in
                                NavigationLink(destination: NickView(nick: item.nick)) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack(spacing: 1) {
                                            ForEach(getIcons(item), id: \.self) { icon in
                                                Image(icon)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: scale * 0.8)
                                            }
                                            Text(item.nick.name)
                                                .foregroundStyle(item.nick.getColor())
                                                .bold()
                                                .padding(.leading, 2)
                                        }
                                        Text(item.message).multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: scale))
                                    .padding(.bottom, 2).padding(.top, 0)
                                    .onLongPressGesture(minimumDuration: 0.2, pressing: { pressing in
                                        item.highlighted = pressing
                                    }) {
                                        UIPasteboard.general.setValue(item.message, forPasteboardType: "public.plain-text")
                                    }
                                    .background(itemActive(item)
                                                ? itemHighlightColor: (item.containsBannedWords
                                                                       ? itemAttentionColor : (item.highlighted
                                                                                               ? itemSelectedColor: Color.clear)))
                                }
                                .accentColor(Color.black)
                            }
                        }
                    }
                    .padding([.all], 10)
                    .onChange(of: model.list, {_, _ in
                        DispatchQueue.main.async {
                            if !model.list.isEmpty {
                                withAnimation {
                                    scrollView.scrollTo(model.list.endIndex - 1, anchor: .bottom)
                                }
                            }
                        }
                    })
                    .onAppear {
                        onAppear()
                    }
                    .onDisappear() {
                        onDisappear()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
                    { _ in didBecomeActiveNotification()}
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification))
                    { _ in didEnterBackgroundNotification()}
                }
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            if scale < 36 {
                                scale += 2
                            }
                        } label: {
                            Image(systemName: "textformat.size.larger")
                        }
                        Button {
                            if scale > 16 {
                                scale -= 2
                            }
                        } label: {
                            Image(systemName: "textformat.size.smaller")
                        }
                        Spacer()
                        Button {
                            model.shouldMute.send(true)
                        } label: {
                            Image(systemName: "speaker").resizable().scaledToFit().frame(height: 25).padding(.trailing, 8)
                        }
                        Button {
                            model.shouldRefresh.send(true)
                            twitchIRC.disconnect()
                            checkNeedRefresh()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        Button {
                            showHelp = true
                        } label: {
                            Image(systemName: "questionmark.circle.fill")
                        }
                    }
                }
                .onReceive(timer) { _ in
                    if model.speakerCountdown > 0 {
                        model.speakerCountdown -= 1
                    }
                    if model.speakerCountdown == 0 {
                        model.speakerActive = false
                    }
                    saveNewNicks()
                    checkHeartbeat()
                }
                .navigationDestination(isPresented: $showSettings) {
                    SettingsView(forceShowSettings: $forceShowSettings)
                }
                .navigationDestination(isPresented: $showHelp) {
                    HelpView()
                }
            }
        }
    }
}
    
#Preview {
    ContentView()
        .modelContainer(for: Settings.self, inMemory: true)
}

//


