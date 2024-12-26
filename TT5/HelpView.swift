//
//  HelpView.swift
//  TT5
//
//  Created by Hilxen on 12/19/24.
//

import SwiftUI
import SwiftData
import WebKit

func getAppVersion() -> String {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    return appVersion ?? ""
}

struct FirstLaunchHelpView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Binding var firstLaunch: Bool
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            HelpView(confirmButtonAction: {
                firstLaunch.toggle()
                settings.first!.version = getAppVersion()
                try! modelContext.save()
            })
        }
    }
}

struct HelpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentation
    @Query private var settings: [Settings]
    let content : AttributedString
    let confirmButtonAction: (() -> Void)?
    
    init(confirmButtonAction: (() -> Void)? = nil) {
        let path = Bundle.main.path(forResource: "help", ofType: "md")!
        let str = try! String(contentsOfFile: path, encoding: .utf8)
        self.content = try! AttributedString(
            markdown: str,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            ))
        self.confirmButtonAction = confirmButtonAction
    }
                          
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            if confirmButtonAction != nil {
                HStack(spacing: 10) {
                    Text("Scroll to read and confirm!").padding(.all, 10)
                }.overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(.orange), lineWidth: 5))
                .padding(.all, 10)
            }
            HStack {
                Image("logo").resizable().scaledToFit().frame(height: 50)
                Text("TT5 for Twitch \(getAppVersion())").bold().font(.title)
                Spacer()
            }.padding(.vertical, 5).padding(.horizontal, 10)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(content).padding(.vertical, 5).padding(.horizontal, 20)
                    if confirmButtonAction != nil {
                        Button() {
                            confirmButtonAction!()
                        } label: {
                            Text("Got it!")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.leading, 20)
                    }
                }
            }
        }
    }
}

