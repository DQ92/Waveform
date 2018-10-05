//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

protocol AudioRecorderDelegate: class {
    func recorderStateDidChange(with state: AudioRecorderState)
}
