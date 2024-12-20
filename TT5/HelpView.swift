//
//  HelpView.swift
//  TT5
//
//  Created by Hilxen on 12/19/24.
//

import SwiftUI
import SwiftData

struct HelpView: View {
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Text("Twitch TT5").bold().font(.title)
                Spacer()
            }.padding(.vertical, 5).padding(.horizontal, 20)
            Spacer()
        }
    }
}
