//
// Created by Michał Kos on 2018-10-04.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioModulesManagerProtocol {
    var delegate: AudioModulesManagerDelegate? { get set }
    var resultsDirectoryURL: URL { get }
    var recordingDuration: TimeInterval { get }
    var currentRecordingTime: TimeInterval { get }
    var recordingMode: AudioRecordingMode { get }

    func loadFile(with url: URL) throws
    func recordOrPause(at timeInterval: TimeInterval) throws
    func finishRecording() throws
    func playOrPause(at timeInterval: TimeInterval) throws
    func clearRecordings() throws
}

protocol AudioModulesManagerDelegate: class {
    func loaderStateDidChange(with state: FileDataLoaderState)
    func playerStateDidChange(with state: AudioPlayerState)
    func recorderStateDidChange(with state: AudioRecorderState)
    func processSampleData(_ data: Float)
}

class AudioModulesManager {

    // MARK: - Private properties

    private var recorder: AudioRecorderProtocol = AVFoundationAudioRecorder()
    private var player: AudioPlayerProtocol = AVFoundationAudioPlayer()
    private var loader: FileDataLoaderProtocol = AudioToolboxFileDataLoader()
    private var recordingPermissionsGranted = false

    // MARK: - Public properties

    weak var delegate: AudioModulesManagerDelegate?
    var resultsDirectoryURL: URL {
        return recorder.resultsDirectoryURL
    }
    var recordingDuration: TimeInterval {
        return recorder.duration
    }
    var currentRecordingTime: TimeInterval {
        return recorder.currentTime
    }
    var recordingMode: AudioRecordingMode {
        return recorder.mode
    }

    // MARK: - Initialization

    init() throws {
        try setupRecorder()
        setupPlayer()
        setupMicrophoneController()
    }
}

// MARK: - Setup

extension AudioModulesManager {
    private func setupRecorder() throws {
        recorder.delegate = self
        try recorder.activateSession() { [weak self] permissionGranted in
            self?.recordingPermissionsGranted = permissionGranted
        }
    }

    private func setupPlayer() {
        player.delegate = self
    }

    private func setupMicrophoneController() {
        AudioToolboxMicrophoneController.shared.delegate = self
    }
}

// MARK: - Modules logic

extension AudioModulesManager: AudioModulesManagerProtocol {
    func recordOrPause(at timeInterval: TimeInterval) throws {
        if player.state == .isPlaying {
            player.pause()
        }
        if recorder.recorderState == .isRecording {
            recorder.pause()
        } else {
            try startRecording(at: timeInterval)
        }
    }

    func startRecording(at startTime: TimeInterval) throws {
        if !recordingPermissionsGranted {
            throw AudioRecorderError.recordingPermissionsNotGranted
        }

        if recorder.recorderState == .stopped {
            try recorder.start()
        } else {
            let time = CMTime(seconds: startTime, preferredTimescale: 100)
            let range = CMTimeRange(start: time, duration: kCMTimeZero)
            try recorder.resume(from: range)
        }
    }

    func finishRecording() throws {
        recorder.stop()
        try recorder.finish()
    }

    func loadFile(with url: URL) throws {
        if recorder.recorderState == .isRecording {
            recorder.stop()
        }
        try recorder.openFile(with: url)
        try loader.loadFile(with: url, completion: { [weak self] values, duration in
            guard let caller = self else {
                return
            }
            caller.delegate?.loaderStateDidChange(with: .loaded(values: values, duration: duration))
        })
    }

    func clearRecordings() throws {
        try recorder.clearRecordings()
    }

    func playOrPause(at timeInterval: TimeInterval) throws {
        if player.state == .paused && recorder.recorderState != .isRecording {
            try playFileInRecording(at: timeInterval)
        } else if player.state == .isPlaying {
            player.pause()
        }
    }

    func playFileInRecording(at timeInterval: TimeInterval) throws {
        try recorder.temporallyExportRecordedFileAndGetUrl { [weak self] url in
            guard let URL = url else {
                return
            }
            DispatchQueue.main.async {
                do {
                    try self?.player.playFile(with: URL, at: timeInterval)
                } catch AudioPlayerError.openFileFailed(let error) {
                    Log.error(error)
                } catch {
                    Log.error("Unknown error")
                }
            }
        }
    }
}

extension AudioModulesManager: AudioPlayerDelegate {
    func playerStateDidChange(with state: AudioPlayerState) {
        delegate?.playerStateDidChange(with: state)
    }
}

extension AudioModulesManager: FileDataLoaderDelegate {
    func loaderStateDidChange(with state: FileDataLoaderState) {
        delegate?.loaderStateDidChange(with: state)
    }
}

extension AudioModulesManager: AudioRecorderDelegate {
    func recorderStateDidChange(with state: AudioRecorderState) {
        delegate?.recorderStateDidChange(with: state)
        switch state {
            case .isRecording:
                AudioToolboxMicrophoneController.shared.start()
            case .paused, .stopped, .fileLoaded:
                AudioToolboxMicrophoneController.shared.stop()
        }
    }
}

extension AudioModulesManager: MicrophoneControllerDelegate {
    func processSampleData(_ data: Float) {
        delegate?.processSampleData(data)
    }
}
