//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AVFoundation

protocol RecorderProtocol {
    var currentTime: TimeInterval { get }
    var isRecording: Bool { get }
    var resultsDirectoryURL: URL { get }
    var delegate: RecorderDelegate? { get set }

    func start(with overwrite: Bool) throws
    func stop()
    func resume(from timeRange: CMTimeRange)
    func pause()
    func crop(startTime: Double, endTime: Double)
    func finish() throws
    func clearRecordings() throws
}
