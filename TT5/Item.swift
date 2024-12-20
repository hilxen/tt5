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
    
    init(nick: Nick, message: String) {
        self.nick = nick
        self.message = message
    }
}
