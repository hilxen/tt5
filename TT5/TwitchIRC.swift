//
//  TwitchIRC.swift
//  TT5
//
//  Created by Hilxen on 12/14/24.
//
import SwiftUI
import TwitchIRC


protocol TwitchIRCDelegate {
    func onMessage(pm: PrivateMessage)
    func onNotification(text: String)
}


class TwitchIRC: WebSocketConnectionDelegate, ObservableObject {
//    @Published var items = [Item]()
//    @Published var toasterText: String = ""
//    @Published var showingToaster: Bool = false
//    @Published var timeRemaining: Int = 5
//    let audioManager: AudioManager = AudioManager.shared
//    let maxMessages: Int = 100
    var channel: String = ""
    var delegate: TwitchIRCDelegate?
    var connected: Bool = false

    var webSocketConnection: WebSocketConnection!
    
    func isConnected() -> Bool {
        return webSocketConnection != nil && connected
    }
    
    func connect() {
        if webSocketConnection == nil || !connected {
            webSocketConnection = WebSocketTaskConnection(url: URL(string: "wss://irc-ws.chat.twitch.tv/")!)
            webSocketConnection.delegate = self
            webSocketConnection.connect()
        }
    }
    
    func disconnect() {
        if webSocketConnection != nil {
            webSocketConnection.disconnect()
            webSocketConnection.delegate = nil
            webSocketConnection = nil
        }
        connected = false
    }

    func onConnected(connection: WebSocketConnection) {
        print("Connected")
        let nick = "justinfan\(Int.random(in: 0...80000) + 1000)"
        let pass = "SCHMOOPIIE"
        let caps = [Capability.tags, Capability.commands];
        send(OutgoingMessage.capabilities(caps))
        send(OutgoingMessage.pass(pass: pass))
        send(OutgoingMessage.nick(name: nick))
        if !channel.isEmpty {
            join(channel: channel)
        }
        connected = true
    }
    
    func onDisconnected(connection: WebSocketConnection, error: Error?) {
        if let error = error {
            print("Disconnected with error:\(error)")
        } else {
            print("Disconnected normally")
        }
        connected = false
    }
    
    func onError(connection: WebSocketConnection, error: Error) {
        print("Connection error:\(error)")
    }
    
    func join(channel: String) {
        if !self.channel.isEmpty {
            send(OutgoingMessage.part(from: self.channel))
        }
        self.channel = channel
        if !self.channel.isEmpty {
            send(OutgoingMessage.join(to: self.channel))
        }
    }

    func send(_ message: OutgoingMessage) {
        let text = message.serialize()
        print("Outgoing message: \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
        webSocketConnection.send(text: text)
    }
    
//    func addItem(nick: String, message: String, color: String = "#000000") {
//        DispatchQueue.main.async {
//            self.items.append(Item(nick: nick, message: message, color: color))
//            let bots = ["", "nighbot", "moobot"]  // move to settings
//            if !bots.contains(nick.lowercased()) {
//                let messageEncoded = message.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//                let url = "https://ancq5cs6vo5xysowyp6qttq2he0aexqb.lambda-url.us-west-1.on.aws/"
//                + "?language-code=ru-RU"
//                + "&voice-id=Tatyana"
//                + "&username=\(nick)"
//                + "&text=\(messageEncoded)"
//                self.audioManager.startAudio(url: url)
//                self.toasterText = nick
//                self.showingToaster = true
//                self.timeRemaining = 5
//            }
//            if self.items.count > self.maxMessages {
//                self.items.removeFirst()
//            }
//        }
//    }
    
    func onMessage(connection: WebSocketConnection, text: String) {
        print("Incoming message: \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
        let twitchMessages: [(message: IncomingMessage?, text: String)] = IncomingMessage.parse(ircOutput: text)
        for (message, _) in twitchMessages {
            switch message {
            case .ping:
                send(.pong)
            case .pong:
                send(.ping)
            case .roomState(let state):
                //addItem(nick: "", message: "joined channel \(state.channel)")
                delegate?.onNotification(text: "joined channel \(state.channel)")
            case .part(let part):
                //addItem(nick: "", message: "left channel \(part.channel)")
                delegate?.onNotification(text: "left channel \(part.channel)")
            case .connectionNotice(let notice):
                if notice.number == 376 {
                    //addItem(nick: "", message: "connected to Twitch")
                    delegate?.onNotification(text: "connected to Twitch")
                }
            case .privateMessage(let pm):
                //addItem(nick: pm.userLogin, message: pm.message, color: pm.color)
                delegate?.onMessage(pm: pm)
            default: break
            }
        }
    }
    
    func onMessage(connection: WebSocketConnection, data: Data) {
        print("Data message: \(data)")
    }
}
