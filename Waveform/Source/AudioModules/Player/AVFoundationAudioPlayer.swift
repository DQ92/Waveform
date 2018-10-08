//
//  AVFoundationAudioPlayer.swift
//  Waveform
//
//  Created by Michał Kos on 12/09/2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AVFoundation

class AVFoundationAudioPlayer: NSObject {
    
    // MARK: - Public properties
    
    weak var delegate: AudioPlayerDelegate?
    var state: AudioPlayerState = .paused

    // MARK: - Private properties
    
    private var player: AVAudioPlayer!
    
    // MARK: - Setup
    
    private func preparePlayer(with URL: URL) throws {
        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try AVAudioSession.sharedInstance().setActive(true)
        
        player = try AVAudioPlayer(contentsOf: URL, fileTypeHint: AVFileType.m4a.rawValue) ~> AudioPlayerError.openFileFailed
        player.delegate = self
    }

    private func changePlayerState(with state: AudioPlayerState) {
        self.state = state
        delegate?.playerStateDidChange(with: state)
    }
}

extension AVFoundationAudioPlayer: AudioPlayerProtocol {
    func playFile(with URL: URL, at timeInterval: TimeInterval) throws {
        if player?.url == nil || player?.url != URL {
            try preparePlayer(with: URL)
        }
        
        if timeInterval > player.duration {
            return
        }

        player.currentTime = timeInterval
        player.play()

        Log.info("Playing file - url: \(URL), duration: \(player.duration), from: \(timeInterval)")
        changePlayerState(with: .playing)
    }
    
    func pause() {
        player.pause()
        Log.info("Player paused by user")
        changePlayerState(with: .paused)
    }
}

extension AVFoundationAudioPlayer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Log.warning("Player paused by delegate")
        changePlayerState(with: .paused)
    }
}
