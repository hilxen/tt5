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


class Model: ObservableObject{
    @Published var list = [Item]()
    @Published var toasterText: String = ""
    @Published var showingToaster: Bool = false
    @Published var timeRemaining: Int = 5
    @Published var shouldRefresh = CurrentValueSubject<Bool, Never>(false)
}

struct ContentView: View, TwitchIRCDelegate {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query private var nicks: [Nick]
    @ObservedObject private var twitchIRC = TwitchIRC()
    @State private var showSettings = false
    @State private var scale = 18.0
    @State private var vibrate: Bool = false
    @ObservedObject private var model = Model()

    let audioManager: AudioManager = AudioManager.shared
    let maxMessages: Int = 20
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        twitchIRC.delegate = self
    }
    
    func initSettings() {
        if settings.isEmpty {
            modelContext.insert(Settings(channel: "", volume: 5, defaultMuted: false))
            try! modelContext.save()
        }
    }
    
    func onAppear() {
        initSettings()
        if twitchIRC.isConnected() && twitchIRC.channel != settings.first!.channel {
            twitchIRC.join(channel: settings.first!.channel)
        }
        audioManager.setVolume(settings.first!.volume)
        if settings.first!.channel.isEmpty {
            showSettings = true
        }
        model.shouldRefresh.send(true)
    }
    
    func didBecomeActiveNotification() {
        initSettings()
        twitchIRC.disconnect()
        twitchIRC.channel = settings.first!.channel
        twitchIRC.connect()
        if settings.first!.channel.isEmpty {
            showSettings = true
        }
        model.shouldRefresh.send(true)
    }
    
    func didEnterBackgroundNotification() {
        // twitchIRC.disconnect()
    }
    
    func onMessage(pm: PrivateMessage) {
        DispatchQueue.main.async {
            addItem(nick: pm.userLogin, text: pm.message, color: pm.color)
        }
    }
    
    func onNotification(text: String) {
        DispatchQueue.main.async {
            addItem(nick: "", text: text)
        }
    }
    
    func toggleMuted(item: Item) {
        if let index = nicks.firstIndex(where: {$0.nick == item.nick}) {
            modelContext.delete(nicks[index])
        } else {
            modelContext.insert(Nick(nick: item.nick, muted: !settings.first!.defaultMuted))
        }
        try! modelContext.save()
    }
    
    func isMuted(item: Item) -> Bool {
        if let index = nicks.firstIndex(where: {$0.nick == item.nick}) {
            return nicks[index].muted
        } else {
            return settings.first!.defaultMuted
        }
    }
    
    func addItem(nick: String, text: String, color: String = "#000000") {
        print("addItem model.list.count=\(model.list.count)")
        let item = Item(nick: nick, message: text, color: color)
        model.list.append(item)
        let bots = ["", "nightbot", "moobot"]  // move to settings
        if !bots.contains(nick.lowercased()) && !isMuted(item: item) {
            playText(nick: nick, text: text)
            model.toasterText = nick
            model.showingToaster = true
            model.timeRemaining = 5
        }
        if model.list.count > maxMessages {
            model.list.removeFirst()
        }
    }

    
    func playText(nick: String, text: String) {
        audioManager.textToSpeech(text: text)
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
            if !settings.first!.channel.isEmpty {
                TwitchPlayerWebView(shouldRefresh: model.shouldRefresh)
                    .frame(height: 200)
                    .padding([.all], 5)
            }
            ZStack {
                ScrollViewReader { scrollView in
                    ScrollView(.vertical) {
                        LazyVStack {
                            ForEach(Array(model.list.enumerated()), id: \.offset) { index, item in
                                HStack {
                                    let icon = isMuted(item: item) != settings.first!.defaultMuted
                                            ? (isMuted(item: item) ? "speaker.slash": "speaker") : ""
                                    if icon != "" {
                                        Image(systemName: icon)
                                    }
                                    Text(item.nick).foregroundStyle(item.getColor()).bold()
                                        .onLongPressGesture {
                                            toggleMuted(item: item)
                                            vibrate.toggle()
                                        }
                                        .sensoryFeedback(.success, trigger: vibrate)
                                    Spacer()
                                    Text(item.message)
                                        .onTapGesture {
                                            playText(nick: item.nick, text: item.message)
                                            vibrate.toggle()
                                        }
                                        .sensoryFeedback(.success, trigger: vibrate)
                                }
                                .font(.system(size: scale))
                                .padding([.bottom], 1)
//                                .addFullSwipeAction(menu: .slided,
//                                                    swipeColor: .white) {
//                                    Leading {
//                                        Button {
//                                            print("edge: .leading")
//                                        } label: {
//                                            Label("Unmute", systemImage: "speaker")
//                                        }
//                                        .padding([.all], 5)
//                                    }
//                                    Trailing {
//                                        Button {
//                                            print("edge: .trailing")
//                                        } label: {
//                                            Label("Mute", systemImage: "speaker.slash")
//                                        }
//                                        .padding([.all], 5)
//                                    }
//                                } action: {
//                                }
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
            }.popup(isPresented: $model.showingToaster) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                            .inset(by: 5) // inset value should be same as lineWidth in .stroke
                            .stroke(.gray, lineWidth: 5)
                            .frame(height: 100)
                            .opacity(100.0)
                            .background(Color.white)
                    Text(model.toasterText).font(.system(size: 50))
                        .foregroundStyle(Color.purple).bold()
                }.onReceive(timer) { _ in
                    if model.timeRemaining > 0 {
                        model.timeRemaining -= 1
                    } else {
                        model.showingToaster = false
                    }
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
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}


    
#Preview {
    ContentView()
        .modelContainer(for: Settings.self, inMemory: true)
}

//


