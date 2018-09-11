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
    
    // MARK: - Private properties
    
    private let tempDirectoryName = "temp_audio"
    private let resultDirectoryName = "results"
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let tempDirectoryURL = FileManager.default.temporaryDirectory
    private let libraryDirectoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory,
                                                               in: .userDomainMask).first!
    
    private var audioRecorder: AVAudioRecorder!
    private var isAudioRecordingPermissionGranted: Bool = true
    private let fileManager = FileManager.default
    private var totalDuration: Float = 0
    private var currentDuration: Float = 0
    private var resultFileNamePrefix: String = "result"
    private var temporaryFileNameSuffix: Int = 0
    private var recorderState: RecorderState = .notInitialized
    
    // MARK: - Setup
    
    func prepare(with clear: Bool) throws {
        if clear {
            temporaryFileNameSuffix = 0
            removeTemporaryDirectory()
        }
        try createTemporaryDirectoryIfNeeded()
        try createResultsDirectoryIfNeeded()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        temporaryFileNameSuffix += 1
        let filename = "temp_\(temporaryFileNameSuffix).m4a"
        audioRecorder = try AVAudioRecorder(url: getTemporaryFileUrl(with: filename), settings: settings)
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        recorderState.changeState(with: .initialized)
    }
}

// MARK: - Dictionaries

extension AVFoundationRecorder {
    private func removeTemporaryDirectory() {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(tempDirectoryName)")
        try? fileManager.removeItem(at: dictPath) ~> RecorderError.directoryDeletionFailed
    }
    
    private func removeResultsDirectory() {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(resultDirectoryName)")
        try? fileManager.removeItem(at: dictPath) ~> RecorderError.directoryDeletionFailed
    }
    
    private func createTemporaryDirectoryIfNeeded() throws {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(tempDirectoryName)")
        if !fileManager.fileExists(atPath: dictPath.path) {
            try fileManager.createDirectory(atPath: dictPath.path,
                                            withIntermediateDirectories: true,
                                            attributes: nil) ~> RecorderError.directoryCreationFailed
        }
        Log.info("Document directory is \(dictPath)")
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
    
    func getTemporaryFileUrl(with fileName: String) -> URL {
        let dict = documentsURL.appendingPathComponent(tempDirectoryName)
        let filePath = dict.appendingPathComponent(fileName)
        return filePath
    }
    
    func listFiles() {
        listContentOfDirectory(at: documentsURL.appendingPathComponent(tempDirectoryName))
    }
    
    func getAllTemporaryAudioParts() throws -> [AVAsset] {
        let urlString = documentsURL.appendingPathComponent(tempDirectoryName)
        var listing = try FileManager.default.contentsOfDirectory(atPath: urlString.path) ~> RecorderError.directoryContentListingFailed
        var assets = [AVAsset]()
        listing = listing.sorted(by: { $0 < $1 })
        totalDuration = 0
        
        for file in listing {
            let fileURL = urlString.appendingPathComponent(file)
            print("FILE URL: \(fileURL)")
            let asset = AVAsset(url: fileURL)
            totalDuration += assetDuration(asset)
            assets.append(asset)
        }
        return assets
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
    
    func start(with overwrite: Bool) throws {
        try startRecording(with: overwrite)
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
    
    func resume() {
        changeRecorderStateWithViewUpdate(with: .isRecording)
        Log.debug("Resumed")
        audioRecorder.record()
    }
    
    func pause() {
        changeRecorderStateWithViewUpdate(with: .paused)
        Log.debug("Paused")
        audioRecorder.pause()
        listFiles()
    }
    
    func finish() throws {
        let assets = try getAllTemporaryAudioParts()
        var assetToExport: AVAsset
        if assets.count > 1 {
            assetToExport = try merge(assets)
        } else if let asset = assets.first {
            assetToExport = asset
        } else {
            Log.error("No assets to export at \(documentsURL)")
            throw RecorderError.fileExportFailed
        }
        
        exportAsset(assetToExport)
    }
    
    func crop(sourceURL: URL, startTime: Double, endTime: Double, completion: ((_ outputUrl: URL) -> Void)? = nil) {
        let asset = AVAsset(url: sourceURL)
        let length = assetDuration(asset)
        Log.info("length asset to crop: \(length) seconds")
        
        if (endTime > Double(length)) {
            Log.error("Error! endTime > length")
        }
        
        var outputURL = documentsURL.appendingPathComponent(tempDirectoryName)
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
    func startRecording(with overwrite: Bool) throws {
        guard isAudioRecordingPermissionGranted else {
            throw RecorderError.noMicrophoneAccess
        }
        
        try prepare(with: !overwrite)
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(AVAudioSessionCategoryPlayAndRecord,
                                with: .defaultToSpeaker) ~> RecorderError.sessionCategoryInvalid
        try session.setActive(true) ~> RecorderError.sessionActivationFailed
        
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        Log.debug("startRecording")
        
        changeRecorderStateWithViewUpdate(with: .isRecording)
    }
    
    private func merge(_ assets: [AVAsset]) throws -> AVAsset {
        let filesPathString = documentsURL.appendingPathComponent(tempDirectoryName)
        
        print("\n----------------------------")
        print("MERGE: \(filesPathString.path)")
        
        var atTimeM: CMTime = kCMTimeZero
        let composition: AVMutableComposition = AVMutableComposition()
        var totalTime: CMTime = kCMTimeZero
        let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                                preferredTrackID: kCMPersistentTrackID_Invalid)!
        for asset in assets {
            if asset == assets.first {
                atTimeM = kCMTimeZero
            } else {
                atTimeM = totalTime // <-- Use the total time for all the audio so far.
            }
            
            Log.debug("Total Time: \(totalTime)")
            if let track = asset.tracks(withMediaType: AVMediaType.audio).first {
                
                try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration),
                                               of: track,
                                               at: atTimeM) ~> RecorderError.timeRangeInsertFailed
                totalTime = CMTimeAdd(totalTime, asset.duration)
                
            } else {
                Log.error("Track retrival while merging failed")
            }
        }
        
        return composition
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
