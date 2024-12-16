//
//  AudioManager.swift
//  TT5
//
//  Created by Hilxen on 12/7/24.
//

import Foundation
import AVFoundation

final class AudioManager {
    static let shared = AudioManager()
    
    private var player: AVQueuePlayer?
    
    private var session = AVAudioSession.sharedInstance()
    
    private var volume: Int = 10
    
    private init() {}
    
    private func activateSession() {
        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: []
            )
        } catch _ {}
        
        do {
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch _ {}
        
        do {
            try session.overrideOutputAudioPort(.speaker)
        } catch _ {}
    }
    
    func setVolume(_ volume: Int) {
        self.volume = volume
    }
    
    
    func startAudio(url: String) {
        activateSession()
        let url = URL(string: url)
        let playerItem: AVPlayerItem = AVPlayerItem(url: url!)
        if let player = player {
            player.insert(playerItem, after: nil)
        } else {
            player = AVQueuePlayer(playerItem: playerItem)
        }
        if let player = player {
            player.volume = 10.0 * Float(volume)
            player.play()
        }
    }
    
    func deactivateSession() {
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch let error as NSError {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}
