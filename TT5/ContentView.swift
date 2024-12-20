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
    @Published var newNicks = [Nick]()
    @Published var shouldRefresh = CurrentValueSubject<Bool, Never>(false)
}

struct ContentView: View, TwitchIRCDelegate {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query private var nicks: [Nick]
    @ObservedObject private var twitchIRC = TwitchIRC()
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var scale = 18.0
    @State private var vibrate: Bool = false
    @ObservedObject private var model = Model()
    @ObservedObject private var audioManager: AudioManager = AudioManager.shared
    //@State private var simpleModelActor: SimpleModelActor!
    
    let maxMessages: Int = 20
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        twitchIRC.delegate = self
    }
    
    func initSettings() {
        if settings.isEmpty {
            modelContext.insert(Settings(channel: "", volume: 5, muted: false, rate: .normal, pitch: .normal, voice: .female))
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
        model.shouldRefresh.send(true)
        //simpleModelActor = SimpleModelActor(modelContainer: modelContext.container)
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
            addItem(nick: nick, text: pm.message, messageId: pm.messageId)
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
        if let nick = nicks.first(where: {$0.name == name}) {
            nick.volume = nick.volume ?? Volume.normal.rawValue
            nick.rate = nick.rate ?? _settings.rate
            nick.pitch = nick.pitch ?? _settings.pitch
            nick.voice = nick.voice ?? _settings.voice
            return nick
        } else {
            let nick = Nick(name: name, muted: _settings.muted)
            nick.volume = Volume.normal.rawValue
            nick.rate = _settings.rate
            nick.pitch = _settings.pitch
            nick.voice = _settings.voice
            model.newNicks.append(Nick(name: name, muted: _settings.muted))
//            if simpleModelActor != nil {
//                Task {
//                    await simpleModelActor.insert(nick: Nick(name: name, muted: _settings.muted))
//                }
//            }
            return nick
        }
    }
    
    func saveNewNicks() {
        for nick in model.newNicks {
            modelContext.insert(nick)
            print("Saved new nick", nick.name)
        }
        model.newNicks.removeAll()
    }
    
    func addItem(nick: Nick, text: String, messageId: String) {
        print("addItem model.list.count=\(model.list.count)")
        let item = Item(nick: nick, message: text)
        model.list.append(item)
        let bots = ["", "nightbot", "moobot", "streamelements"]  // move to settings
        if !bots.contains(nick.name.lowercased()) && !nick.muted {
            playText(nick: nick, text: text, messageId: messageId)
        }
        if model.list.count > maxMessages {
            model.list.removeFirst()
        }
    }

    
    func playText(nick: Nick, text: String, messageId: String) {
        audioManager.textToSpeech(settings: settings.first!, nicks: nicks, nick: nick, text: text, messageId: messageId)
//        let textEncoded = text.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        let url = "https://ancq5cs6vo5xysowyp6qttq2he0aexqb.lambda-url.us-west-1.on.aws/"
//        + "?language-code=ru-RU"
//        + "&voice-id=Tatyana"
//        + "&username=\(nick)"
//        + "&text=\(textEncoded)"
//        audioManager.startAudio(url: url)
    }
    
    var body: some View {
        NavigationStack {
            if !settings.isEmpty && !settings.first!.channel.isEmpty {
                TwitchPlayerWebView(shouldRefresh: model.shouldRefresh)
                    .frame(height: 200)
                    .padding([.all], 5)
            }
            ZStack {
                ScrollViewReader { scrollView in
                    ScrollView(.vertical) {
                        LazyVStack {
                            ForEach(Array(model.list.enumerated()), id: \.offset) { index, item in
                                HStack(alignment: .top, spacing: 0) {
                                    let icon = item.nick.muted != settings.first!.muted
                                        ? (item.nick.muted ? "speaker.slash": "speaker") : ""
                                    if icon != "" {
                                        Image(systemName: icon)
                                    }
                                    NavigationLink(destination: NickView(nick: item.nick)) {
                                        HStack(spacing: 1) {
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
                                    }
                                    Spacer()
                                    Text(item.message)
                                        .onTapGesture {
                                            playText(nick: item.nick, text: item.message, messageId: "")
                                            vibrate.toggle()
                                        }
                                        .sensoryFeedback(.success, trigger: vibrate)
                                }
                                .font(.system(size: scale))
                                .padding([.bottom], 1)
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
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
                    { _ in didBecomeActiveNotification()}
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification))
                    { _ in didEnterBackgroundNotification()}
                }
            }.popup(isPresented: $audioManager.speakerActive) {
                ZStack {
                    if let speakerNick = audioManager.speakerNick {
                        RoundedRectangle(cornerRadius: 20)
                            .inset(by: 5) // inset value should be same as lineWidth in .stroke
                            .stroke(.gray, lineWidth: 5)
                            .frame(height: 100)
                            .opacity(100.0)
                            .background(Color.white)
                        NavigationLink(destination: NickView(nick: speakerNick)) {
                            Text(speakerNick.name).font(.system(size: 50))
                                .foregroundStyle(speakerNick.getColor())
                                .bold()
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .padding(.horizontal, 20)
                        }
                    }
                }.onReceive(timer) { _ in
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
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
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
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        model.shouldRefresh.send(true)
                    } label: {
                        Image(systemName: "arrow.trianglehead.clockwise")
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
        }
    }
}

//final actor SimpleModelActor: ModelActor {
//    let modelExecutor: any ModelExecutor
//    let modelContainer: ModelContainer
//    let context: ModelContext
//    
//    init(modelContainer: ModelContainer) {
//        self.modelContainer = modelContainer
//        self.context = ModelContext(modelContainer)
//        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
//    }
//    
//    func insert(nick: Nick) {
//        context.insert(nick)
//        try! context.save() // this does not impact a re-display by the @Query in ContentView. I would have expected it to cause a view redraw.
//    }
//}

    
#Preview {
    ContentView()
        .modelContainer(for: Settings.self, inMemory: true)
}

//


