//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AVFoundation

protocol RecorderProtocol {
    var currentTime: TimeInterval { get }
    var isRecording: Bool { get }

    func start() throws
    func stop()
    func resume()
    func pause()
    func crop(startTime: Double, endTime: Double)
    func merge() throws
}
