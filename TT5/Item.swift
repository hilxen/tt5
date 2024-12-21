//
//  Item.swift
//  TT5
//
//  Created by Hilxen on 12/1/24.
//

import Foundation
import SwiftData


@Model
final class Item {
    var nick: Nick
    var message: String
    var messageId: String
    var skipped: Bool = false
    
    init(nick: Nick, message: String, messageId: String) {
        self.nick = nick
        self.message = message
        self.messageId = messageId
    }
}
