//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AVFoundation

class AVFoundationRecorder: NSObject {
    
    // MARK: - Public properties
    
    weak var delegate: RecorderDelegate?
    
    var resultsDirectoryURL: URL {
        return documentsURL.appendingPathComponent(resultDirectoryName)
    }
    
    var mode: RecordingMode {
        let numberOfComponents = self.components.count
        
        if numberOfComponents > 1 {
            return .override(turn: numberOfComponents - 1)
        }
        return .normal
    }
    
    // MARK: - Private properties
    
    private let resultDirectoryName = "results"
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let tempDirectoryUrl: URL
    
    private var audioRecorder: AVAudioRecorder!
    private let fileManager = FileManager.default
    private var totalDuration: Float = 0
    private var currentDuration: Float = 0
    private var resultFileNamePrefix: String = "result"
    private var recorderState: RecorderState = .notInitialized
    private var components: [AssetComponent] = []
    private var duration: CMTime = kCMTimeZero
    
    // MARK: - Initialization
    
    override init() {
        self.tempDirectoryUrl = self.documentsURL.appendingPathComponent("temp_audio")
    }
    
    // MARK: - Setup
    
    func setupAudioRecorder(fileName: String) throws {
        let url = self.tempDirectoryUrl.appendingPathComponent(fileName)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
    }
}

// MARK: - Dictionaries

extension AVFoundationRecorder {
    private func removeTemporaryDirectory() {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: self.tempDirectoryUrl) ~> RecorderError.directoryDeletionFailed
    }
    
    private func removeResultsDirectory() {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: self.tempDirectoryUrl) ~> RecorderError.directoryDeletionFailed
    }
    
    private func createTemporaryDirectoryIfNeeded() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: self.tempDirectoryUrl.path) {
            try fileManager.createDirectory(atPath: self.tempDirectoryUrl.path,
                                            withIntermediateDirectories: true,
                                            attributes: nil) ~> RecorderError.directoryCreationFailed
        }
        Log.info("Document directory is \(self.tempDirectoryUrl)")
    }
    
    private func createResultsDirectoryIfNeeded() throws {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(resultDirectoryName)")
        if !fileManager.fileExists(atPath: dictPath.path) {
            try fileManager.createDirectory(atPath: dictPath.path,
                                            withIntermediateDirectories: true,
                                            attributes: nil) ~> RecorderError.directoryCreationFailed
        }
        Log.info("Document directory is \(dictPath)")
    }
}


// MARK: - Files

extension AVFoundationRecorder {
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

extension AVFoundationRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Log.debug("audioRecorderDidFinishRecording")
    }
}

// MARK: - Recorder state

extension AVFoundationRecorder {
    func changeRecorderStateWithViewUpdate(with state: RecorderState) {
        recorderState.changeState(with: state)
        delegate?.recorderStateDidChange(with: state)
    }
}

extension AVFoundationRecorder: RecorderProtocol {
    var currentTime: TimeInterval {
        if recorderState == .notInitialized {
            return 0.0
        }
        return audioRecorder.currentTime
    }
    
    var isRecording: Bool {
        if recorderState == .notInitialized {
            return false
        }
        return audioRecorder.isRecording
    }
    
    var currentlyRecordedFileURL: URL? {
        if recorderState == .notInitialized {
            return nil
        }
        return audioRecorder.url
    }
    
    func activateSession(permissionBlock: @escaping (Bool) -> Void) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(AVAudioSessionCategoryPlayAndRecord,
                                with: .defaultToSpeaker) ~> RecorderError.sessionCategoryInvalid
        try session.setActive(true) ~> RecorderError.sessionActivationFailed
        session.requestRecordPermission(permissionBlock)
    }
    
    func start() throws {
        removeTemporaryDirectory()
        components.removeAll()
        
        try createTemporaryDirectoryIfNeeded()
        try createResultsDirectoryIfNeeded()
        
        let filename = "temp_\(components.count).m4a"
        let timeRange = CMTimeRange(start: kCMTimeZero, duration: kCMTimeZero)
        try self.setupAudioRecorder(fileName: filename)
        
        recorderState.changeState(with: .initialized)
        
        components.append(AssetComponent(fileName: filename, timeRange: timeRange))
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        Log.debug("startRecording")
        
        changeRecorderStateWithViewUpdate(with: .isRecording)
    }
    
    func stop() {
        Log.debug("Stopped")
        changeRecorderStateWithViewUpdate(with: .stopped)
        audioRecorder?.stop()
        audioRecorder = nil
        recorderState.changeState(with: .notInitialized)
        Log.debug("Recorded successfully.")
        listFiles()
    }
    
    func resume(from timeRange: CMTimeRange) throws {
        let possibleTimeDiffernce = CMTime(seconds: 0.05, preferredTimescale: 100)
        
        if self.duration - timeRange.start <= possibleTimeDiffernce {
            audioRecorder.record()
            Log.debug("Resumed")
        } else {
            let filename = "temp_\(components.count).m4a"
            try self.setupAudioRecorder(fileName: filename)
            
            components.append(AssetComponent(fileName: filename, timeRange: timeRange))
            audioRecorder.prepareToRecord()
            audioRecorder.record()
            
            Log.debug("Overwrite")
        }
        changeRecorderStateWithViewUpdate(with: .isRecording)
    }
    
    func pause() {
        if let timeRange = self.components.last?.timeRange {
            let currentAudioDuration = CMTime(seconds: self.audioRecorder.currentTime, preferredTimescale: 100)
            
            if timeRange.duration.value > 0 {
                self.duration = self.duration - timeRange.duration + currentAudioDuration
            } else {
                let endTime = timeRange.start + currentAudioDuration
                
                if endTime > self.duration {
                    self.duration = endTime
                }
            }
        }
        changeRecorderStateWithViewUpdate(with: .paused)
        Log.debug("Paused")
        audioRecorder.pause()
        listFiles()
    }
    
    func finish() throws {
        let result = try self.merge(components: self.components)
        self.exportAsset(result)
    }
    
    func crop(sourceURL: URL, startTime: Double, endTime: Double, completion: ((_ outputUrl: URL) -> Void)? = nil) {
        let asset = AVAsset(url: sourceURL)
        let length = assetDuration(asset)
        Log.info("length asset to crop: \(length) seconds")
        
        if (endTime > Double(length)) {
            Log.error("Error! endTime > length")
        }
        
        var outputURL = self.tempDirectoryUrl
        do {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
        } catch let error {
            Log.error(error)
        }
        let preferredTimescale = WaveformConfiguration.preferredTimescale
        let timeRange = CMTimeRange(start: CMTime(seconds: startTime,
                                                  preferredTimescale: preferredTimescale),
                                    end: CMTime(seconds: endTime, preferredTimescale: preferredTimescale))
        
        try? fileManager.removeItem(at: outputURL)
        guard let exportSession = AVAssetExportSession(asset: asset,
                                                       presetName: AVAssetExportPresetHighestQuality) else {
                                                        return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                Log.info("CROPPED exported at \(outputURL)")
                completion?(outputURL)
            case .failed:
                Log.error("failed \(exportSession.error.debugDescription)")
            case .cancelled:
                Log.warning("cancelled \(exportSession.error.debugDescription)")
            default: break
            }
        }
    }
    
    func clearRecordings() throws {
        removeResultsDirectory()
        try createResultsDirectoryIfNeeded()
    }
    
    func crop(startTime: Double, endTime: Double) {
        
    }
}

// MARK: - Files operations

extension AVFoundationRecorder {
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
                                                 at: component.timeRange.start) ~> RecorderError.timeRangeInsertFailed
        }
        return audioComposition
    }
    
    private func exportAsset(_ asset: AVAsset) {
        let resultPathString = documentsURL.appendingPathComponent(resultDirectoryName)
        let resultFileName = generateResultFileName()
        let finalURL = resultPathString.appendingPathComponent(resultFileName)
        
        Log.debug("EXPORTING ....\(finalURL)")
        
        if let exportSession = AVAssetExportSession(asset: asset,
                                                    presetName: AVAssetExportPresetHighestQuality) {
            exportSession.outputURL = finalURL
            exportSession.outputFileType = .mp4
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    Log.info("exported at \(finalURL)")
                case .failed:
                    Log.error("failed \(exportSession.error.debugDescription)")
                case .cancelled:
                    Log.warning("cancelled \(exportSession.error.debugDescription)")
                default: break
                }
            }
        }
    }
}
