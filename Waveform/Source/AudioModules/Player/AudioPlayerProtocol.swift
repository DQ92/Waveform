//
//  PlayerProtocol.swift
//  Waveform
//
//  Created by Michał Kos on 12/09/2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import Foundation

protocol AudioPlayerProtocol {
    var delegate: AudioPlayerDelegate? { get set }
    var state: AudioPlayerState { get }

    func playFile(with URL: URL, at timeInterval: TimeInterval) throws
    func pause()
}
