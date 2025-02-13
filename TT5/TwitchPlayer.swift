//
//  TwitchPlayer.swift
//  TT5
//
//  Created by Hilxen on 12/15/24.
//

import WebKit
import SwiftUI
import SwiftData
import Combine

struct TwitchPlayerWebView: UIViewRepresentable {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    let shouldRefresh: CurrentValueSubject<Bool, Never>
    let shouldPlay: CurrentValueSubject<Bool, Never>
    let shouldMute: CurrentValueSubject<Bool, Never>
    private let webView: WKWebView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.allowsPictureInPictureMediaPlayback = true
        context.coordinator.navigation = reload()
        context.coordinator.webView = self
        context.coordinator.observeChangesRefresh(for: shouldRefresh)
        context.coordinator.observeChangesPlay(for: shouldPlay)
        context.coordinator.observeChangesMute(for: shouldMute)
        return webView
    }
    
    func reload() -> WKNavigation? {
        let channel = settings.first!.channel.trimmingCharacters(in: .whitespacesAndNewlines)
        return webView.load(URLRequest(url: URL(string: "https://player.twitch.tv/?channel=\(channel)&parent=localhost&autoplay=true&allowfullscreen")!))
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // This space can be left blank
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

extension TwitchPlayerWebView {
    class Coordinator {
        var navigation: WKNavigation?
        var webView: TwitchPlayerWebView?
        private var cancellableRefresh: AnyCancellable?
        private var cancellablePlay: AnyCancellable?
        private var cancellableMute: AnyCancellable?
        
        func observeChangesRefresh(for shouldRefresh: CurrentValueSubject<Bool, Never>) {
            cancellableRefresh = shouldRefresh
                .filter { $0 == true }
                .sink { [weak self] newValue in
                    self?.navigation = self?.webView?.reload()
                }
        }
        
        func observeChangesPlay(for shouldPlay: CurrentValueSubject<Bool, Never>) {
            cancellablePlay = shouldPlay
                .filter { $0 == true }
                .sink { [weak self] newValue in
                    self?.webView?.webView.evaluateJavaScript("document.querySelector(\"#channel-player > div > div.Layout-sc-1xcs6mc-0.cFsYRp.player-controls__left-control-group > div.InjectLayout-sc-1i43xsx-0.kBtJDm > button\").click()") { (result, error) in
                    }
                }
        }

        func observeChangesMute(for shouldMute: CurrentValueSubject<Bool, Never>) {
            cancellableMute = shouldMute
                .filter { $0 == true }
                .sink { [weak self] newValue in
                    self?.webView?.webView.evaluateJavaScript("document.querySelector(\"#channel-player > div > div.Layout-sc-1xcs6mc-0.cFsYRp.player-controls__left-control-group > div:nth-child(2) > div > div.Layout-sc-1xcs6mc-0.hdWbbR > div > button\").click()") { (result, error) in
                    }
                }
        }
    }
}
