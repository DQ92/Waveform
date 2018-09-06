//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation
import AVFoundation

class AVFoundationRecorder: NSObject {
    
    // MARK: - Public properties
    
    weak var delegate: RecorderDelegate?
    var currentTime: TimeInterval {
        return audioRecorder.currentTime
    }
    var isRecording: Bool {
        return audioRecorder.isRecording
    }

    // MARK: - Private properties
    
    private let tempDictName = "temp_audio"
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let tempDirectoryURL = FileManager.default.temporaryDirectory
    private let libraryDirectoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory,
                                                               in: .userDomainMask).first!
    
    private var audioRecorder: AVAudioRecorder!
    private var isAudioRecordingGranted: Bool = true
    private let fileManager = FileManager.default
    private var totalDuration: Float = 0
    private var currentDuration: Float = 0
    private var fileNameSuffix: Int = 0
    
    func prepare(with clear: Bool) throws {
        if clear {
            try removeTempDict()
            try createDictInTemp()
        }
    }
    
    func startRecording() throws {
        AudioController.sharedInstance.start()
        
        guard isAudioRecordingGranted else {
            throw RecorderError.noMicrophoneAccess
        }
        
        Log.debug("startRecording")
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(AVAudioSessionCategoryPlayAndRecord,
                                with: .defaultToSpeaker) ~> RecorderError.sessionCategoryInvalid
        try session.setActive(true) ~> RecorderError.sessionActivationFailed
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        fileNameSuffix = fileNameSuffix + 1
        audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        
        delegate?.recorderStateDidChange(with: .isRecording)
    }
    
    func assetDuration(_ asset: AVAsset) -> Float {
        return Float(asset.duration.value) / Float(asset.duration.timescale)
    }
    
    func listFiles() {
        listContentOfDirectory(at: documentsURL.appendingPathComponent(tempDictName))
    }
    
    func getFileUrl() -> URL {
        let filename = "rec_\(fileNameSuffix).m4a"
        let dict = documentsURL.appendingPathComponent(tempDictName)
        let filePath = dict.appendingPathComponent(filename)
        return filePath
    }
    
    func removeTempDict() throws {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(tempDictName)")
        try fileManager.removeItem(at: dictPath) ~> RecorderError.directoryDeletionFailed
    }
    
    func createDictInTemp() throws {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(tempDictName)")
        if !fileManager.fileExists(atPath: dictPath.path) {
            try fileManager.createDirectory(atPath: dictPath.path,
                                            withIntermediateDirectories: true,
                                            attributes: nil) ~> RecorderError.directoryCreationFailed
        }
        Log.info("Document directory is \(dictPath)")
    }
    
    func getAllAudioParts() throws -> [AVAsset] {
        let urlString = documentsURL.appendingPathComponent(tempDictName)
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
    
}

// MARK: - Helper

extension AVFoundationRecorder {
    func listContentOfDirectory(at url: URL) {
        do {
            let listing = try FileManager.default.contentsOfDirectory(atPath: url.path)
            
            if listing.count > 0 {
                print("\n----------------------------")
                print("LISTING: \(url.path) \n")
                for file in listing {
                    print("File: \(file.debugDescription)")
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

extension AVFoundationRecorder: RecorderProtocol {
    
    func crop(startTime: Double, endTime: Double) {
        
    }
    
    func start() throws {
        try startRecording()
    }
    
    func stop() {
        Log.debug("stopped")
        delegate?.recorderStateDidChange(with: .stopped)
        
        AudioController.sharedInstance.stop()
        audioRecorder?.stop()
        audioRecorder = nil
        Log.debug("recorded successfully.")
        listFiles()
        //        _ = getAllAudioParts()
    }
    
    func resume() {
        delegate?.recorderStateDidChange(with: .isRecording)
        AudioController.sharedInstance.start()
        Log.debug("Resumed")
        audioRecorder.record()
    }
    
    func pause() {
        delegate?.recorderStateDidChange(with: .isRecording)
        
        Log.debug("Paused")
        AudioController.sharedInstance.stop()
        audioRecorder.pause()
        listFiles()
        //        _ = getAllAudioParts()
    }
    
    func merge() throws {
        let assets = try getAllAudioParts()
        let filesPathString = documentsURL.appendingPathComponent(tempDictName)
        
        if assets.count > 1 {
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
                    Log.error("error!!")
                }
                
            }
            
            let finalURL = filesPathString.appendingPathComponent("result.m4a")
            Log.debug("EXPORTING MERGE....\(finalURL)")
            
            if let exportSession = AVAssetExportSession(asset: composition,
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
        } else {
            Log.debug("Brak plików w \(filesPathString.path)")
        }
    }
    
    func crop(sourceURL: URL, startTime: Double, endTime: Double, completion: ((_ outputUrl: URL) -> Void)? = nil) {
        let asset = AVAsset(url: sourceURL)
        let length = assetDuration(asset)
        Log.info("length asset to crop: \(length) seconds")
        
        if (endTime > Double(length)) {
            Log.error("Error! endTime > length")
        }
        
        var outputURL = documentsURL.appendingPathComponent(tempDictName)
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
}

func ~><T>(expression: @autoclosure () throws -> T,
           errorTransform: (Error) -> Error) throws -> T {
    do {
        return try expression()
    } catch {
        throw errorTransform(error)
    }
}
