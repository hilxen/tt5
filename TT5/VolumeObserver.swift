//
//  VolumeObserver.swift
//  TT5
//
//  Copyright (c) Hilxen. MIT License.
//

import Foundation
import MediaPlayer

final class VolumeObserver: ObservableObject {
    @Published var volume: Float = AVAudioSession.sharedInstance().outputVolume
    private let session = AVAudioSession.sharedInstance()
    private var progressObserver: NSKeyValueObservation!
    
    func subscribe() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("cannot activate session")
        }
        
        progressObserver = session.observe(\.outputVolume) { [self] (session, value) in
            DispatchQueue.main.async {
                self.volume = session.outputVolume
            }
        }
    }
    
    func unsubscribe() {
        self.progressObserver.invalidate()
    }
    
    init() {
        subscribe()
    }
}
