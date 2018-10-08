//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AVFoundation

class AVFoundationAudioRecorder: NSObject {

    // MARK: - Public properties

    weak var delegate: AudioRecorderDelegate?
    var mode: AudioRecordingMode {
        let numberOfComponents = self.components.count
        if numberOfComponents > 1 {
            return .override(turn: numberOfComponents - 1)
        }
        return .normal
    }
    var resultsDirectoryURL: URL
    var recorderState: AudioRecorderState = .stopped

    // MARK: - Private properties

    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let tempDirectoryUrl: URL
    private let tempExportDirectoryUrl: URL
    private var audioRecorder: AVAudioRecorder?
    private let fileManager = FileManager.default
    private var totalDuration: Float = 0
    private var components: [AssetComponent] = []
    private var durationTime: CMTime = kCMTimeZero

    // MARK: - Initialization

    override init() {
        self.tempDirectoryUrl = self.documentsURL.appendingPathComponent("temp_audio")
        self.resultsDirectoryURL = self.documentsURL.appendingPathComponent("results")
        self.tempExportDirectoryUrl = self.documentsURL.appendingPathComponent("temp_exp")
    }

    // MARK: - Setup

    private func setupAudioRecorder(fileName: String) throws {
        let url = self.tempDirectoryUrl.appendingPathComponent(fileName)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
    }

    private func resetDirectories() throws {
        let directoriesToRemove = [self.tempDirectoryUrl, self.tempExportDirectoryUrl]
        for url in directoriesToRemove {
            try self.removeDirectory(url: url)
        }
        let directoriesToCreate = [self.tempDirectoryUrl, self.tempExportDirectoryUrl, self.resultsDirectoryURL]
        for url in directoriesToCreate {
            try self.createDirectoryIfNeeded(url: url)
        }
    }
    
    private func currentDurationTime() -> CMTime {
        if let timeRange = self.components.last?.timeRange {
            let currentTime = self.audioRecorder?.currentTime ?? 0.0
            let currentAudioDuration = CMTime(seconds: currentTime, preferredTimescale: 100)

            if timeRange.duration.value > 0 {
                return self.durationTime - timeRange.duration + currentAudioDuration
            } else {
                let endTime = timeRange.start + currentAudioDuration
                if endTime > self.durationTime {
                    return endTime
                } else {
                    return self.durationTime
                }
            }
        }
        return kCMTimeZero
    }
}

// MARK: - Dictionaries

extension AVFoundationAudioRecorder {
    private func removeDirectory(url: URL) throws {
        try? FileManager.default.removeItem(at: url) ~> AudioRecorderError.directoryDeletionFailed
    }

    private func createDirectoryIfNeeded(url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(atPath: url.path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil) ~> AudioRecorderError.directoryCreationFailed
        }
    }
}

// MARK: - Files

extension AVFoundationAudioRecorder {
    func generateResultFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM.dd.yyyy-hh:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "\(dateString).m4a"
        return fileName
    }

    func listFiles() {
        listContentOfDirectory(at: self.tempDirectoryUrl)
    }

    func assetDuration(_ asset: AVAsset) -> Float {
        return Float(asset.duration.value) / Float(asset.duration.timescale)
    }

    func listContentOfDirectory(at url: URL) {
        do {
            let listing = try FileManager.default.contentsOfDirectory(atPath: url.path)
            if listing.count > 0 {
                print("\n----------------------------")
                print("LISTING: \(url.path) \n")
                listing.sorted().forEach {
                    print("File: \($0.debugDescription)")
                }
                print("")
                print("----------------------------\n")
            } else {
                print("Brak plików w \(url.path)")
            }
        } catch {
        }
    }
}

extension AVFoundationAudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Log.debug("audioRecorderDidFinishRecording")
//        changeRecorderStateWithViewUpdate(with: .stopped)
    }
}

// MARK: - Recorder state

extension AVFoundationAudioRecorder {
    func changeRecorderStateWithViewUpdate(with state: AudioRecorderState) {
        recorderState = state
        delegate?.recorderStateDidChange(with: state)
    }
}

extension AVFoundationAudioRecorder: AudioRecorderProtocol {
    var currentTime: TimeInterval {
        guard let currentTime = audioRecorder?.currentTime else {
            return 0.0
        }
        return currentTime
    }

    var duration: TimeInterval {
        let durationTime = currentDurationTime()
        return TimeInterval(durationTime.value) / TimeInterval(durationTime.timescale)
    }
    
    var currentlyRecordedFileURL: URL? {
        guard let URL = audioRecorder?.url else {
            return nil
        }
        return URL
    }

    func activateSession(permissionBlock: @escaping (Bool) -> Void) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(AVAudioSessionCategoryPlayAndRecord,
                                with: .defaultToSpeaker) ~> AudioRecorderError.sessionCategoryInvalid
        try session.setActive(true) ~> AudioRecorderError.sessionActivationFailed
        session.requestRecordPermission(permissionBlock)
    }

    func start() throws {
        try self.resetDirectories()
        self.components.removeAll()
        let filename = "temp_\(components.count).m4a"
        let timeRange = CMTimeRange(start: kCMTimeZero, duration: kCMTimeZero)
        try self.setupAudioRecorder(fileName: filename)
        components.append(AssetComponent(fileName: filename, timeRange: timeRange))
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        Log.debug("startRecording")
        changeRecorderStateWithViewUpdate(with: .started)
    }

    func stop() {
        Log.debug("Stopped")
        changeRecorderStateWithViewUpdate(with: .stopped)
        audioRecorder?.stop()
        audioRecorder = nil
        Log.debug("Recorded successfully.")
        listFiles()
    }

    func resume(from timeRange: CMTimeRange) throws {
        let possibleTimeDifference = CMTime(seconds: 0.05, preferredTimescale: 100)
        if let recorder = audioRecorder, self.durationTime - timeRange.start <= possibleTimeDifference {
            recorder.record()
            Log.debug("Resumed")
        } else {
            let filename = "temp_\(components.count).m4a"
            try self.setupAudioRecorder(fileName: filename)
            components.append(AssetComponent(fileName: filename, timeRange: timeRange))
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            Log.debug("Overwrite")
        }
        changeRecorderStateWithViewUpdate(with: .resumed)
    }

    func pause() {
        audioRecorder?.pause()
        durationTime = currentDurationTime()
        changeRecorderStateWithViewUpdate(with: .paused)
        Log.debug("Paused")
        listFiles()
    }

    func finish() throws {
        if components.isEmpty {
            return
        }
        let result = try self.merge(components: self.components)
        
        self.durationTime = kCMTimeZero
        self.exportAsset(result, destinationDictionaryURL: resultsDirectoryURL)
    }

    func crop(sourceURL: URL, startTime: Double, endTime: Double, completion: ((_ outputUrl: URL) -> Void)? = nil) {
//        if recorderState == .notInitialized {
//            return
//        }
//        let asset = AVAsset(url: sourceURL)
//        let length = assetDuration(asset)
//        Log.info("length asset to crop: \(length) seconds")
//
//        if (endTime > Double(length)) {
//            Log.error("Error! endTime > length")
//        }
//
//        var outputURL = self.tempDirectoryUrl
//        do {
//            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
//            outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
//        } catch let error {
//            Log.error(error)
//        }
//        let preferredTimescale = WaveformConfiguration.preferredTimescale
//        let timeRange = CMTimeRange(start: CMTime(seconds: startTime,
//                                                  preferredTimescale: preferredTimescale),
//                                    end: CMTime(seconds: endTime, preferredTimescale: preferredTimescale))
//
//        try? fileManager.removeItem(at: outputURL)
//        guard let exportSession = AVAssetExportSession(asset: asset,
//                                                       presetName: AVAssetExportPresetHighestQuality) else {
//            return
//        }
//        exportSession.outputURL = outputURL
//        exportSession.outputFileType = .mp4
//        exportSession.timeRange = timeRange
//        exportSession.exportAsynchronously {
//            switch exportSession.status {
//                case .completed:
//                    Log.info("CROPPED exported at \(outputURL)")
//                    completion?(outputURL)
//                case .failed:
//                    Log.error("failed \(exportSession.error.debugDescription)")
//                case .cancelled:
//                    Log.warning("cancelled \(exportSession.error.debugDescription)")
//                default: break
//            }
//        }
    }

    func clearRecordings() throws {
        try self.removeDirectory(url: self.resultsDirectoryURL)
        try self.createDirectoryIfNeeded(url: self.resultsDirectoryURL)
    }

    func crop(startTime: Double, endTime: Double) {
    }

    func temporallyExportRecordedFileAndGetUrl(completion: @escaping (_ url: URL?) -> Void) throws {
        try exportRecordedFile(at: tempExportDirectoryUrl, completion: completion)
    }

    private func exportRecordedFile(at destination: URL, completion: @escaping (_ url: URL?) -> Void) throws {
        if let recorder = audioRecorder, recorderState != .stopped {
            Log.debug("Recorder paused")
            recorderState = .paused
            recorder.stop()
            audioRecorder = nil
        }
        if components.isEmpty {
            completion(nil)
            return
        }
        let result = try self.merge(components: self.components)
        exportAsset(result, destinationDictionaryURL: destination, completion: completion)
    }

    func openFile(with url: URL) throws {
        try resetDirectories()
        self.components.removeAll()
        let filename = "temp_\(components.count).m4a"
        try FileManager.default.copyItem(at: url, to: self.tempDirectoryUrl.appendingPathComponent(filename))
        let timeRange = CMTimeRange(start: kCMTimeZero, duration: kCMTimeZero)
        components.append(AssetComponent(fileName: filename, timeRange: timeRange))
        durationTime = AVURLAsset(url: url).duration
        
        Log.debug("openFile")
        changeRecorderStateWithViewUpdate(with: .fileLoaded)
    }
}

// MARK: - Files operations

extension AVFoundationAudioRecorder {
    private func merge(components: [AssetComponent]) throws -> AVAsset {
        let audioComposition = AVMutableComposition()
        for component in components {
            let asset = component.loadAsset(directoryUrl: self.tempDirectoryUrl)
            let removeTimeRange: CMTimeRange
            if component.timeRange.duration.value > 0 {
                removeTimeRange = component.timeRange
            } else {
                let duration = audioComposition.duration - component.timeRange.start
                if duration < asset.duration {
                    removeTimeRange = CMTimeRange(start: component.timeRange.start, duration: duration)
                } else {
                    removeTimeRange = CMTimeRange(start: component.timeRange.start, duration: asset.duration)
                }
            }
            audioComposition.removeTimeRange(removeTimeRange)
            try audioComposition.insertTimeRange(CMTimeRange(start: kCMTimeZero, duration: asset.duration),
                                                 of: asset,
                                                 at: component.timeRange.start) ~> AudioRecorderError.timeRangeInsertFailed
        }
        return audioComposition
    }

    private func exportAsset(_ asset: AVAsset,
                             destinationDictionaryURL: URL,
                             completion: @escaping (_ url: URL?) -> Void = { _ in
                             }) {
        let resultFileName = generateResultFileName()
        let finalURL = destinationDictionaryURL.appendingPathComponent(resultFileName)
        Log.debug("EXPORTING ....\(finalURL)")
        if let exportSession = AVAssetExportSession(asset: asset,
                                                    presetName: AVAssetExportPresetHighestQuality) {
            exportSession.outputURL = finalURL
            exportSession.outputFileType = .mp4
            exportSession.exportAsynchronously {
                switch exportSession.status {
                    case .completed:
                        Log.info("exported at \(finalURL)")
                        completion(finalURL)
                    case .failed:
                        Log.error("failed \(exportSession.error.debugDescription)")
                        completion(nil)
                    case .cancelled:
                        Log.warning("cancelled \(exportSession.error.debugDescription)")
                        completion(nil)
                    default: break
                }
            }
        }
    }
}
