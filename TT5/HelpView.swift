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

struct HelpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentation
    @Query private var settings: [Settings]
    @State var showOK = false
    @State var text = """
<html>
<head>
    <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'/>
</head>
<body style="font-family: arial">
<p>
    A text to speech app for Twitch. Reads comments posted to a channel.
    The app is useful for both channel owners and viewers, so they do not need to read comments from the screen,
    but instead use earpiece or speaker.
</p>
<p>
    The app can be put into background, so you can run other streaming apps like PRISM Live at the same time,
    or simply put your phone in a pocket
</p>
<p>
    How to put the app into background <a target="_blank" href="https://youtu.be/NGAhAvaZAsQ">watch this short demo</a>. 
    Tap "play" button on stream preview, and then to view it in a popup. This puts the app into background! 
    Now you can open other apps or lock your phone.
</p>
<p>
    Tip: if you are a streamer you can prevent hearing yourself by increasing speech volume in settings or keep stream preview on mute  
<p>
<h3>Features</h3>
<ul>
    <li>
        No login required
    </li>
    <li>
        Twitch channel view and reading comments is anonymous
    </li>
    <li>
        The app does not collect any data
    </li>
    <li>
        Background mode
    </li>
    <li>
        Languages and voices - all supported by Apple's Text to Speech
    </li>
    <li>
        Automatic language recognition
    </li>
    <li>
        Customize speach at app level or for individual nicks - Voice, Volume, Rate, Pitch
    </li>
    <li>
        Mute/unmute nicks by role or individually
    </li>
    <li>
        Customize nick's pronunciation
    </li>
</ul>
<h3>Contact me</h3>
<p>
    The app is provided free of charge, but any help will be appreciated. Subscribe to my Twitch channel, Telegram or donate. Even $1 helps!
</p>
<ul>
    <li>
        My Twitch channel <a target="_blank" href="https://www.twitch.tv/hilxen">twitch.tv/hilxen</a>
    </li>
    <li>
        Telegram
        <ul>
            <li>
                Channel &amp; chat <a target="_blank" href="https://t.me/hilxens">t.me/hilxens</a>
            </li>
            <li>
                Private message <a target="_blank" href="https://t.me/hilxen">t.me/hilxen</a>
            </li>
        </ul>
    </li>
    <li>
        Donations <a target="_blank" href="https://www.donationalerts.com/r/hilxen">donationalerts.com/r/hilxen</a>
    </li>
</ul>
</body></html>
"""

    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Image("logo").resizable().scaledToFit().frame(height: 50)
                Text("TT5 for Twitch \(getAppVersion())").bold().font(.title)
                Spacer()
            }.padding(.vertical, 5).padding(.horizontal, 10)
            
            WebView(text: $text)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .padding(.vertical, 5).padding(.horizontal, 10)
            Spacer()
            if showOK {
                Button() {
                    settings.first!.version = getAppVersion()
                    try! modelContext.save()
                    presentation.wrappedValue.dismiss()
                } label: {
                    Text("Got it!")
                }
                .buttonStyle(.borderedProminent)
                .padding(.leading, 20)
            }
        }.onAppear {
            showOK = (settings.first!.version ?? "") != getAppVersion()
        }.toolbar {
            if showOK {
                HStack(spacing: 10) {
                    Text("Scroll to read!").padding(.all, 10)
                }.overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(.orange), lineWidth: 5))
               .padding(.all, 5)
            }
        }
    }
}

struct WebView: UIViewRepresentable {
  @Binding var text: String
   
  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }
   
  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(text, baseURL: nil)
  }
}
