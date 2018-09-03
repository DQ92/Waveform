//
//  AudioContext.swift
//  Waveform
//
//  Created by Robert Mietelski on 03.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit
import AVFoundation

struct AudioContext {

    // MARK: - Public attributes
    
    let audioURL: URL
    let totalSamples: Int
    let asset: AVAsset
    let assetTrack: AVAssetTrack
    
    // MARK: - Initialization
    
    private init(audioURL: URL, totalSamples: Int, asset: AVAsset, assetTrack: AVAssetTrack) {
        self.audioURL = audioURL
        self.totalSamples = totalSamples
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
                        
                        let totalSamples = Int((asbd.pointee.mSampleRate) * Float64(asset.duration.value) / Float64(asset.duration.timescale))
                        let context = AudioContext(audioURL: audioURL, totalSamples: totalSamples, asset: asset, assetTrack: assetTrack)
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
