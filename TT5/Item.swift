//
//  Item.swift
//  TT5
//
//  Created by Hilxen on 12/1/24.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Item {
    var nick: String
    var color: String
    var message: String
    
    init(nick: String, message: String, color: String = "#000000") {
        self.nick = nick
        self.color = color
        self.message = message
    }
    
    func getColor() -> Color {
        var hexSanitized = self.color.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return Color.black }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return Color.black
        }

        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
