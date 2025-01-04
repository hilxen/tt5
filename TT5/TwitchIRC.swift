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
        self.channel = channel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !self.channel.isEmpty {
            send(OutgoingMessage.join(to: self.channel))
        }
    }

    func send(_ message: OutgoingMessage) {
        let text = message.serialize()
        print("Outgoing message: \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
        webSocketConnection.send(text: text)
    }
    
    func onMessage(connection: WebSocketConnection, text: String) {
        print("Incoming message: \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
        let twitchMessages: [(message: IncomingMessage?, text: String)] = IncomingMessage.parse(ircOutput: text)
        delegate?.heartbeat()
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
