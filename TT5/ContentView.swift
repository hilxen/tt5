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


class Model: ObservableObject {
    @Published var list = [Item]()
    @Published var newNicks = [String: Nick]()
    @Published var shouldRefresh = CurrentValueSubject<Bool, Never>(false)
}

struct ContentView: View, TwitchIRCDelegate {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query private var nicks: [Nick]
    @Query(filter: #Predicate<Language> { $0.enabled }) private var enabledLanguages: [Language]

    @ObservedObject private var twitchIRC = TwitchIRC()
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var scale = 18.0
    @State private var vibrate: Bool = false
    @State private var previousChannel: String = ""
    @ObservedObject private var model = Model()
    @ObservedObject private var audioManager: AudioManager = AudioManager.shared
    
    let maxMessages: Int = 20
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        twitchIRC.delegate = self
    }
    
    func initSettings() {
        if settings.isEmpty {
            modelContext.insert(Settings(channel: "", volume: 1, muted: false, rate: .normal, pitch: .normal, voice: .female,
                                         mods: true, vips: true, subscribers: true, broadcaster: true, highlighted: true))
            try! modelContext.save()
        }
    }
    
    func onAppear() {
        initSettings()
        
        let _settings = settings.first!
        if twitchIRC.isConnected() && twitchIRC.channel != _settings.channel {
            twitchIRC.join(channel: _settings.channel)
        }
        if _settings.channel.isEmpty {
            showSettings = true
        }
        //model.shouldRefresh.send(true)
        audioManager.contentViewActive = true
        audioManager.speechTools.recognizer.languageConstraints = enabledLanguages.map({NLLanguage($0.languageCode())})
        
        var enabledVoices = [String: [String: String]]()
        for language in enabledLanguages {
            enabledVoices[language.languageCode()] = [
                "female": language.femaleVoiceId ?? language.maleVoiceId!,
                "male": language.maleVoiceId ?? language.femaleVoiceId!
            ]
        }
        audioManager.speechTools.voices = enabledVoices
        if previousChannel != settings.first!.channel {
            model.shouldRefresh.send(true)
            previousChannel = settings.first!.channel
            model.list.removeAll()
        }
    }
    
    func onDisappear() {
        audioManager.contentViewActive = false
    }
    
    func didBecomeActiveNotification() {
        initSettings()
        let _settings = settings.first!
        twitchIRC.disconnect()
        twitchIRC.channel = _settings.channel
        twitchIRC.connect()
        if _settings.channel.isEmpty {
            showSettings = true
        }
        model.shouldRefresh.send(true)
    }
    
    func didEnterBackgroundNotification() {
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
            DispatchQueue.global(qos: .background).async {
                audioManager.textToSpeech(settings: copyOfSettings, nicks: nicks, item: item)
            }
        }
    }
    
    func onNotification(text: String) {
//        DispatchQueue.main.async {
//            addItem(nick: nil, text: text)
//        }
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
    
        
    var body: some View {
        NavigationStack {
            if !settings.isEmpty && !settings.first!.channel.isEmpty {
                TwitchPlayerWebView(shouldRefresh: model.shouldRefresh)
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
                                        let icon = item.skipped ? "play.slash"
                                        : (item.nick.muted != settings.first!.muted)
                                        ? (item.nick.muted ? "speaker.slash": "speaker") : ""
                                        if icon != "" {
                                            Image(systemName: icon)
                                        }
                                        if item.nick.mod ?? false {
                                            Image("mod").resizable().scaledToFit().frame(height: scale * 0.8)
                                        }
                                        if item.nick.subscriber ?? false {
                                            Image("sub").resizable().scaledToFit().frame(height: scale * 0.8)
                                        }
                                        if item.nick.vip ?? false {
                                            Image("vip").resizable().scaledToFit().frame(height: scale * 0.8)
                                        }
                                        if item.nick.broadcaster ?? false {
                                            Image("own").resizable().scaledToFit().frame(height: scale * 0.8)
                                        }
                                        Text(item.nick.name).foregroundStyle(item.nick.getColor()).bold().padding(.leading, 2)
                                    }
                                    Text(item.message).multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: scale))
                                .padding(.bottom, 2).padding(.top, 0)
                            }.accentColor(Color.black)
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
                        model.shouldRefresh.send(true)
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
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showHelp) {
                HelpView()
            }
        }.popup(isPresented: $audioManager.speakerActive) {
            ZStack {
                if let speakerNick = audioManager.speakerNick {
                    RoundedRectangle(cornerRadius: 20)
                        .inset(by: 5) // inset value should be same as lineWidth in .stroke
                        .stroke(.gray, lineWidth: 5)
                        .frame(height: 100)
                        .background(Color.white)
                    //NavigationLink(destination: NickView(nick: speakerNick)) {
                        Text(speakerNick.name).font(.system(size: 50))
                            .foregroundStyle(speakerNick.getColor())
                            .bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 20)
                    //}
                }
            }.padding(.top, 200)
            .onReceive(timer) { _ in
                if audioManager.speakerCountdown > 0 {
                    audioManager.speakerCountdown -= 1
                }
                if audioManager.speakerCountdown == 0 {
                    audioManager.speakerActive = false
                }
                saveNewNicks()
            }
        } customize: {
            $0
                .type(.floater())
                .appearFrom(.topSlide)
                .position(.top)
                .animation(.spring())
                .closeOnTapOutside(true)
        }
    }
}
    
#Preview {
    ContentView()
        .modelContainer(for: Settings.self, inMemory: true)
}

//


