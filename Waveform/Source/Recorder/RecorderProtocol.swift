//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import AVFoundation

enum RecordingMode {
    case normal
    case override(turn: Int)
}

protocol RecorderProtocol {
    var currentTime: TimeInterval { get }
    var delegate: RecorderDelegate? { get set }
    var currentlyRecordedFileURL: URL? { get }
    var mode: RecordingMode { get }
    var recorderState: RecorderState! { get }
    var resultsDirectoryURL: URL { get }

    func activateSession(permissionBlock: @escaping (Bool) -> Void) throws
    func start() throws
    func stop()
    func resume(from timeRange: CMTimeRange) throws
    func pause()
    func crop(startTime: Double, endTime: Double)
    func finish() throws
    func clearRecordings() throws
    func temporallyExportRecordedFileAndGetUrl(completion: @escaping (_ url: URL?) -> Void) throws

}
