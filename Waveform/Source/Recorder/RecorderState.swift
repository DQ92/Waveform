//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

enum RecorderState {
    case isRecording
    case stopped
    case paused
    case notInitialized
    case initialized
    
    mutating func changeState(with state: RecorderState) {
        if state != .initialized && self == .notInitialized {
            Assert.checkRepresentation(false, "Could not change state to \(state) from invalid state: \(self)")
        }
        
        self = state
    }
}
