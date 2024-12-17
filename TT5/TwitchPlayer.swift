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
    private let webView: WKWebView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.allowsPictureInPictureMediaPlayback = true
        context.coordinator.navigation = reload()
        context.coordinator.webView = self
        context.coordinator.observeChanges(for: shouldRefresh)
        return webView
    }
    
    func reload() -> WKNavigation? {
        return webView.load(URLRequest(url: URL(string: "https://player.twitch.tv/?channel=\(settings.first!.channel)&parent=localhost&autoplay=true&allowfullscreen")!))
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
        private var cancellable: AnyCancellable?
        
        @MainActor
        func observeChanges(for shouldRefresh: CurrentValueSubject<Bool, Never>) {
            cancellable = shouldRefresh
                .filter { $0 == true }
                .sink { [weak self] newValue in
                    self?.navigation = self?.webView?.reload()
                }
        }
    }
}
