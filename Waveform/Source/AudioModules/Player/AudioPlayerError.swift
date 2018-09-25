//
//  AudioPlayerError.swift
//  Waveform
//
//  Created by Michał Kos on 12/09/2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import Foundation

enum AudioPlayerError: Error {
    case openFileFailed(Error)
}
