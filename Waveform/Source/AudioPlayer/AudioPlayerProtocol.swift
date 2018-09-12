//
//  PlayerProtocol.swift
//  Waveform
//
//  Created by Michał Kos on 12/09/2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import Foundation

protocol AudioPlayerProtocol {
    func playFile(with URL: URL, at timeInterval: TimeInterval) throws
    func pause()
}
