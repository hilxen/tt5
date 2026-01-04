//
//  Item.swift
//  TT5
//
//  Created by Hilxen on 12/1/24.
//

import Foundation
import SwiftData

final class Emote {
    var id: String
    var start: Int
    var end: Int
    init(id: String, start: Int, end: Int) {
        self.id = id
        self.start = start
        self.end = end
    }
}


final class Item : Equatable {
    var id: String
    var nick: Nick
    var message: String
    var messageId: String
    var emotesStr: String
    var emotes: [Emote]
    var customReward: CustomReward?
    var skipped: Bool = false
    var containsBannedWords: Bool = false
    var highlighted: Bool = false
    var conversation: Bool = false
    
    static func ==(lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String, nick: Nick, message: String, messageId: String, emotes: String, conversation: Bool, customReward: CustomReward?) {
        self.id = id
        self.nick = nick
        self.message = message
        self.messageId = messageId
        self.emotesStr = emotes
        self.emotes = Item.parseEmotes(emotesStr: emotes)
        self.conversation = conversation
        self.customReward = customReward
    }
    
    static func parseEmotes(emotesStr: String) -> [Emote] {
        var result: [Emote] = []
        // Split the string by '/' to separate different emotes
        let emoteComponents = emotesStr.components(separatedBy: "/")
        for component in emoteComponents {
            // Split each component into identifier and range parts
            let parts = component.components(separatedBy: ":")
            if parts.count == 2 {
                let id = parts[0]
                let ranges = parts[1].components(separatedBy: ",")
                for range in ranges {
                    let positions = range.components(separatedBy: "-")
                    if positions.count == 2,
                       let start = Int(positions[0]),
                       let end = Int(positions[1]) {
                        result.append(Emote(id: id, start: start, end: end))
                    }
                }
            }
        }
        return result
    }
}
