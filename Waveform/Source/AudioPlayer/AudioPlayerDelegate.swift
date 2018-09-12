//
//  AudioPlayerDelegate.swift
//  Waveform
//
//  Created by Michał Kos on 12/09/2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation

protocol AudioPlayerDelegate: class {
    func recorderStateDidChange(with state: AudioPlayerState)
}
