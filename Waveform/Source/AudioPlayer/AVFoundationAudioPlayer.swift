//
//  AVFoundationAudioPlayer.swift
//  Waveform
//
//  Created by Michał Kos on 12/09/2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation
import AVFoundation

class AVFoundationAudioPlayer {
    
    // MARK: - Public properties
    
    weak var delegate: AudioPlayerDelegate?
    
    // MARK: - Private properties
    
    private var player: AVAudioPlayer!
    
    // MARK: - setup
    
    private func preparePlayer(with URL: URL) throws {
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try! AVAudioSession.sharedInstance().setActive(true)
        
        player = try AVAudioPlayer(contentsOf: URL, fileTypeHint: AVFileType.m4a.rawValue) ~> AudioPlayerError.openFileFailed
    }
}

extension AVFoundationAudioPlayer: AudioPlayerProtocol {
    func playFile(with URL: URL, at timeInterval: TimeInterval) throws {
        if player?.url == nil || player?.url != URL {
            try preparePlayer(with: URL)
        }
        
        player.currentTime = timeInterval
        player.play()
        
        delegate?.recorderStateDidChange(with: .isPlaying)
    }
    
    func pause() {
        player.pause()
        delegate?.recorderStateDidChange(with: .paused)
    }
}
