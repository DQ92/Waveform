//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AVFoundation

protocol RecorderProtocol {
    var currentTime: TimeInterval { get }
    var delegate: RecorderDelegate? { get set }
    var resultsDirectoryURL: URL { get }
    var recorderState: RecorderState { get }

    func start(with overwrite: Bool) throws
    func stop()
    func resume()
    func pause()
    func crop(startTime: Double, endTime: Double)
    func finish() throws
    func clearRecordings() throws
    func temporallyExportRecordedFileAndGetUrl(completion: @escaping (_ url: URL?) -> Void) throws

}
