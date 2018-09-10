//
//  AudioContext.swift
//  Waveform
//
//  Created by Robert Mietelski on 03.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit
import Accelerate
import AVFoundation

struct AudioContext {

    // MARK: - Public attributes
    
    let audioURL: URL
    let totalSamples: Int
    let numberOfSeconds: Double
    let asset: AVAsset
    let assetTrack: AVAssetTrack
    
    // MARK: - Initialization
    
    private init(audioURL: URL, totalSamples: Int, numberOfSeconds: Double, asset: AVAsset, assetTrack: AVAssetTrack) {
        self.audioURL = audioURL
        self.totalSamples = totalSamples
        self.numberOfSeconds = numberOfSeconds
        self.asset = asset
        self.assetTrack = assetTrack
    }
    
    static func loadAudio(from audioURL: URL, successHandler: ((AudioContext) -> (Void))?, failureHandler: ((Error) -> (Void))?)  {
        let asset = AVURLAsset(url: audioURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true)])
        
        if let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
            asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                var error: NSError?
                
                switch asset.statusOfValue(forKey: "duration", error: &error) {
                case .loaded:
                    if let formatDescriptions = assetTrack.formatDescriptions as? [CMAudioFormatDescription],
                       let audioFormatDesc = formatDescriptions.first,
                       let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc) {
                        
                        let numberOfSeconds = Float64(asset.duration.value) / Float64(asset.duration.timescale)
                        let totalSamples = Int((asbd.pointee.mSampleRate) * numberOfSeconds)

                        let context = AudioContext(audioURL: audioURL,
                                                   totalSamples: totalSamples,
                                                   numberOfSeconds: numberOfSeconds,
                                                   asset: asset,
                                                   assetTrack: assetTrack)
                        successHandler?(context)
                    } else {
                        failureHandler?(AudioContextError.audioFormat)
                    }
                default:
                    failureHandler?(error ?? AudioContextError.unknown)
                }
            }
        } else {
            failureHandler?(AudioContextError.loadFile)
        }
    }
    
    func extractSamples() -> [Float] {
        guard let reader = try? AVAssetReader(asset: self.asset) else {
            return []
        }
        let outputSettingsDict: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let readerOutput = AVAssetReaderTrackOutput(track: self.assetTrack, outputSettings: outputSettingsDict)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)
        
        var channelCount = 1
        let formatDescriptions = self.assetTrack.formatDescriptions as! [CMAudioFormatDescription]
        for item in formatDescriptions {
            guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item) else { return [] }
            channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
        }
        
        let samplesPerPixel = max(1, channelCount)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        
        var outputSamples = [Float]()
        var sampleBuffer = Data()
        
        // 16-bit samples
        reader.startReading()
        defer { reader.cancelReading() } // Cancel reading if we exit early if operation is cancelled
        
        while reader.status == .reading {
            guard let readSampleBuffer = readerOutput.copyNextSampleBuffer(),
                let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
                    break
            }
            // Append audio sample buffer into our current sample buffer
            var readBufferLength = 0
            var readBufferPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(readBuffer, 0, &readBufferLength, nil, &readBufferPointer)
            sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
            CMSampleBufferInvalidate(readSampleBuffer)
            
            let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
            let downSampledLength = totalSamples / samplesPerPixel
            let samplesToProcess = downSampledLength * samplesPerPixel
            
            guard samplesToProcess > 0 else { continue }
            
            processSamples(fromData: &sampleBuffer,
                           outputSamples: &outputSamples,
                           samplesToProcess: samplesToProcess,
                           downSampledLength: downSampledLength,
                           samplesPerPixel: samplesPerPixel,
                           filter: filter)
        }
        
        // Process the remaining samples at the end which didn't fit into samplesPerPixel
        let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
        if samplesToProcess > 0 {
            let downSampledLength = 1
            let samplesPerPixel = samplesToProcess
            let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
            
            processSamples(fromData: &sampleBuffer,
                           outputSamples: &outputSamples,
                           samplesToProcess: samplesToProcess,
                           downSampledLength: downSampledLength,
                           samplesPerPixel: samplesPerPixel,
                           filter: filter)
            //print("Status: \(reader.status)")
        }
        
        // if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown)
        // Something went wrong. Handle it, or not depending on if you can get above to work
        if reader.status == .completed {
            return outputSamples
        }
        return []
    }
    
    func processSamples(fromData sampleBuffer: inout Data, outputSamples: inout [Float], samplesToProcess: Int, downSampledLength: Int, samplesPerPixel: Int, filter: [Float]) {
        sampleBuffer.withUnsafeBytes { (samples: UnsafePointer<Int16>) in
            var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
            
            let sampleCount = vDSP_Length(samplesToProcess)
            
            //Convert 16bit int samples to floats
            vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)
            
            //Take the absolute values to get amplitude
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
            
            //Downsample and average
            var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter, &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
            
            // Remove processed samples
            sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)
            
            outputSamples += downSampledData
        }
    }
}

enum AudioContextError: Error, LocalizedError {
    case loadFile, audioFormat, unknown
    
    var errorDescription: String? {
        switch self {
        case .loadFile:
            return "Failed to load AVAssetTrack"
        case .audioFormat:
            return "Failed to read audio format description"
        case .unknown:
            return "Unknown error"
        }
    }
}
