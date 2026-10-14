//
//  TwitchPlayer.swift
//  TT5
//
//  Copyright (c) Hilxen. MIT License.
//

import WebKit
import SwiftUI
import SwiftData
import Combine

protocol TwitchPlayerDelegate {
    func videoMuteState(muted: Bool)
}


struct TwitchPlayerWebView: UIViewRepresentable {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    let shouldRefresh: CurrentValueSubject<Bool, Never>
    let shouldMute: CurrentValueSubject<Bool, Never>
    let shouldHeartbeat: CurrentValueSubject<Bool, Never>
    let delegate: TwitchPlayerDelegate
    private let webView: WKWebView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.allowsPictureInPictureMediaPlayback = true
        webView.navigationDelegate = context.coordinator
        context.coordinator.navigation = reload()
        context.coordinator.webView = self
        context.coordinator.observeChangesRefresh(for: shouldRefresh)
        context.coordinator.observeChangesMute(for: shouldMute)
        context.coordinator.observeChangesHeartbeat(for: shouldHeartbeat)
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
    class Coordinator: NSObject, WKNavigationDelegate {
        var navigation: WKNavigation?
        var webView: TwitchPlayerWebView?
        private var cancellableRefresh: AnyCancellable?
        private var cancellableMute: AnyCancellable?
        private var cancellableHeartbeat: AnyCancellable?
        
        func observeChangesRefresh(for shouldRefresh: CurrentValueSubject<Bool, Never>) {
            cancellableRefresh = shouldRefresh
                .filter { $0 == true }
                .sink { [weak self] newValue in
                    self?.navigation = self?.webView?.reload()
                }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.triggerPIP(webView: self.webView!.webView)
        }

        func triggerPIP(webView: WKWebView) {
            let javaScript = """
            (function() {
                function isVideoInPictureInPicture(video) {
                    // Check using WebKit API (iOS-specific)
                    if (video.webkitPresentationMode) {
                        return video.webkitPresentationMode === 'picture-in-picture';
                    }
                    // Fallback to standard Picture-in-Picture API
                    if (document.pictureInPictureElement) {
                        return document.pictureInPictureElement === video;
                    }
                    return false;
                }
                function triggerPictureInPicture(intervalId) {
                    // document.querySelector(\"#channel-player > div > div.Layout-sc-1xcs6mc-0.cFsYRp.player-controls__left-control-group > div.InjectLayout-sc-1i43xsx-0.kBtJDm > button\").click();
                    const video = document.querySelector('video');
                    if (isVideoInPictureInPicture(video)) {
                        clearInterval(intervalId);
                        return;
                    }
                    if (video) {
                        if (video.webkitSetPresentationMode) {
                            video.webkitSetPresentationMode('picture-in-picture');
                            // clearInterval(intervalId);
                        } else if (video.requestPictureInPicture) {
                            video.requestPictureInPicture().then(() => {
                                // clearInterval(intervalId);
                            }).catch(error => {
                                console.error('Failed to enter Picture-in-Picture mode:', error);
                            });
                        } else {
                            console.error('Picture-in-Picture not supported on this video element');
                        }
                    } else {
                        console.error('No video element found');
                    }
                }

                function pollForVideoElement(attempts, interval) {
                    let attempt = 0;
                    const intervalId = setInterval(() => {
                        const video = document.querySelector('video');
                        if (video) {
                            // clearInterval(intervalId);
                            setTimeout(() => {
                                triggerPictureInPicture(intervalId);
                            }, 3000);
                        } else if (attempt >= attempts) {
                            clearInterval(intervalId);
                            console.error('Video element not found after maximum attempts');
                        }
                        attempt++;
                    }, interval);
                }

                pollForVideoElement(20, 3000);
            })();
            """
            
            // Execute the JavaScript in the WKWebView
            webView.evaluateJavaScript(javaScript) { (result, error) in
                if let error = error {
                    print("Error executing JavaScript: \(error)")
                } else {
                    print("Picture-in-Picture triggered successfully")
                }
            }

        }
        
        func observeChangesMute(for shouldMute: CurrentValueSubject<Bool, Never>) {
            cancellableMute = shouldMute
                .filter { $0 == true }
                .sink { [weak self] newValue in
                    self?.toggleVideoMuteState()
                    self?.isVideoMuted()
                }
        }
        
        func observeChangesHeartbeat(for shouldHeartbeat: CurrentValueSubject<Bool, Never>) {
            cancellableHeartbeat = shouldHeartbeat
                .filter { $0 == true }
                .sink { [weak self] newValue in
                    self?.isVideoMuted()
                }
        }
        
        func isVideoMuted() {
            let javaScript = """
            (function() {
                const video = document.querySelector('video');
                if (video) {
                    return video.muted;
                } else {
                    throw new Error('No video element found');
                }
            })();
            """
            
            self.webView?.webView.evaluateJavaScript(javaScript) { (result, error) in
                if let isMuted = result as? Bool {
                    self.webView?.delegate.videoMuteState(muted: isMuted)
                } else {
                    let error = NSError(domain: "VideoMuteCheckError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to determine mute state"])
                    print("Error checking mute state: \(error)")
                }
            }
        }
        
        func toggleVideoMuteState() {
            let javaScript = """
            (function() {
                return new Promise((resolve, reject) => {
                    const video = document.querySelector('video');
                    if (video) {
                        video.muted = !video.muted;
                        resolve(true);
                    } else {
                        reject(new Error('No video element found'));
                    }
                });
            })();
            """
            
            self.webView?.webView.evaluateJavaScript(javaScript) { (result, error) in
            }
        }
    }
}
