//
// Created by Michał Kos on 2018-10-04.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

class AudioModulesManager {

    // MARK: - Private properties

    private var recorder: AudioRecorderProtocol = AVFoundationAudioRecorder()
    private var recordingPermissionsGranted = false
    private var player: AudioPlayerProtocol = AVFoundationAudioPlayer()
    private var loader: FileDataLoaderProtocol = AudioToolboxFileDataLoader()

    // MARK: - Public properties

    weak var delegate: AudioModulesManagerDelegate?

    // MARK: - Initialization

    init() throws {
        try setup()
    }
}

// MARK: - Setup

extension AudioModulesManager {
    private func setup() throws {
        try setupRecorder()
        setupPlayer()
        setupMicrophoneController()
    }

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
    func recordOrPause() throws {
        if player.state == .isPlaying {
            player.pause()
        }
        if recorder.recorderState == .isRecording {
            recorder.pause()
        } else {
            try startRecording()
        }
    }

    func startRecording() throws {
        Log.info("Start recording")
        if recorder.recorderState == .stopped {
            self.resetCurrentSampleData()
            self.manager.reset()
            try recorder.start()
        } else {
            let time = CMTime(seconds: self.timeInterval, preferredTimescale: 100)
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
        try loader.loadFile(with: url, completion: { [weak self] values in
            guard let caller = self else {
                return
            }
            let samplesPerPoint = CGFloat(values.count) / caller.waveformPlot.bounds.width
            caller.manager.loadData(from: values)
            caller.manager.loadZoom(from: samplesPerPoint)
            caller.waveformPlot.currentPosition = 0.0
            caller.waveformPlot.reloadData()
        })
        totalTimeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: loader.fileDuration))
    }

    func clearRecordings() throws {
        try recorder.clearRecordings()
    }

    func playOrPause() throws {
        if player.state == .paused && recorder.recorderState != .isRecording {
            try playFileInRecording()
        } else if player.state == .isPlaying {
            player.pause()
        }
    }

    func playFileInRecording() throws {
        try recorder.temporallyExportRecordedFileAndGetUrl { [weak self] url in
            guard let URL = url else {
                return
            }
            DispatchQueue.main.async {
                do {
                    let timeInterval = self?.timeInterval ?? 0.0
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
    func playerStateDidChangeBeforeRefactor(with state: AudioPlayerState) {
        switch state {
            case .isPlaying:
                let stepWidth = CGFloat(plotDataManager.layersPerTimeInterval) / CGFloat((100 * plotDataManager.zoomLevel.samplesPerLayer))
                movementCoordinator.startScrolling(stepWidth: stepWidth)
            case .paused:
                movementCoordinator.stopScrolling()
        }
    }
}

extension AudioModulesManager: AudioRecorderDelegate {
    func recorderStateDidChangeBeforeRefactor(with state: AudioRecorderState) {
        switch state {
            case .isRecording:
                AudioToolboxMicrophoneController.shared.start()
            case .stopped:
                AudioToolboxMicrophoneController.shared.stop()
                let samplesPerPoint = CGFloat(self.plotDataManager.numberOfSamples) / self.waveformPlot.bounds.width
                self.plotDataManager.loadZoom(from: samplesPerPoint)
                self.waveformPlot.reloadData()
            case .paused:
                AudioToolboxMicrophoneController.shared.stop()
            case .fileLoaded:
                self.waveformPlot.isUserInteractionEnabled = true // ???
        }
    }
}

extension AudioModulesManager: MicrophoneControllerDelegate {
    func processSampleData(_ data: Float) {
    }
}

protocol AudioModulesManagerProtocol {
    var delegate: AudioModulesManagerDelegate? { get set }

    func loadFile(with url: URL) throws
    func recordOrPause() throws
    func finishRecording() throws
    func playOrPause() throws
    func clearRecordings() throws
}

protocol AudioModulesManagerDelegate: class {
}