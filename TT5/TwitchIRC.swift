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
    func heartbeat()
    func print(_ message: String...)
    func print(_ level: LogLevel, _ message: String...)
}


class TwitchIRC: WebSocketConnectionDelegate {
    var channel: String = ""
    var delegate: TwitchIRCDelegate?
    var connected: Bool = false

    var webSocketConnection: WebSocketConnection!
    
    func isConnected() -> Bool {
        return webSocketConnection != nil && connected
    }
    
    func connect() {
        if webSocketConnection == nil || !connected {
            connected = true
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
        DispatchQueue.main.async {
            self.delegate?.print("Connected")
            let nick = "justinfan\(Int.random(in: 0...80000) + 1000)"
            let pass = "SCHMOOPIIE"
            let caps = [Capability.tags, Capability.commands];
            self.send(OutgoingMessage.capabilities(caps))
            self.send(OutgoingMessage.pass(pass: pass))
            self.send(OutgoingMessage.nick(name: nick))
            if !self.channel.isEmpty {
                self.join(channel: self.channel)
            }
        }
    }

    func onDisconnected(connection: WebSocketConnection, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.delegate?.print(.WARNING, "Disconnected with error:\(error)")
            } else {
                self.delegate?.print("Disconnected normally")
            }
            self.connected = false
        }
    }

    func onError(connection: WebSocketConnection, error: Error) {
        DispatchQueue.main.async {
            self.delegate?.print(.WARNING, "Connection error:\(error)")
        }
    }
    
    func join(channel: String) {
        if !self.channel.isEmpty {
            send(OutgoingMessage.part(from: self.channel))
        }
        self.channel = channel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !self.channel.isEmpty {
            send(OutgoingMessage.join(to: self.channel))
        }
    }

    func send(_ message: OutgoingMessage) {
        let text = message.serialize()
        delegate?.print("Outgoing message: \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
        webSocketConnection.send(text: text)
    }
    
    func onMessage(connection: WebSocketConnection, text: String) {
        DispatchQueue.main.async {
            self.delegate?.print("Incoming message: \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
            let twitchMessages: [(message: IncomingMessage?, text: String)] = IncomingMessage.parse(ircOutput: text)
            self.delegate?.heartbeat()
            for (message, _) in twitchMessages {
                switch message {
                case .ping:
                    self.send(.pong)
                case .pong:
                    self.send(.ping)
                case .roomState(let state):
                    //addItem(nick: "", message: "joined channel \(state.channel)")
                    self.delegate?.onNotification(text: "joined channel \(state.channel)")
                case .part(let part):
                    //addItem(nick: "", message: "left channel \(part.channel)")
                    self.delegate?.onNotification(text: "left channel \(part.channel)")
                case .connectionNotice(let notice):
                    if notice.number == 376 {
                        //addItem(nick: "", message: "connected to Twitch")
                        self.delegate?.onNotification(text: "connected to Twitch")
                    }
                case .privateMessage(let pm):
                    //addItem(nick: pm.userLogin, message: pm.message, color: pm.color)
                    self.delegate?.onMessage(pm: pm)
                default: break
                }
            }
        }
    }

    func onMessage(connection: WebSocketConnection, data: Data) {
        DispatchQueue.main.async {
            self.delegate?.print("Data message: \(data)")
        }
    }
}
