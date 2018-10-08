//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

enum AudioRecorderState {
    case started
    case resumed
    case stopped
    case paused
    case fileLoaded

    var recording: Bool {
        return self == .started || self == .resumed
    }
}
