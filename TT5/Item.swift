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
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
