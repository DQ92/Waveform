//
// Created by Michał Kos on 04/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AudioToolbox

class AudioUtils {
    
    // MARK: - Constants
    
    static let defaultWaveformFloatModifier: Float = 500
    static let defaultSampleRate: Double = 44100
    static let defaultZoomMultipliers: [Double] = [0, 0.25, 0.5, 0.75, 1]

    // MARK: - Rms evaluating

    static func toRMS(buffer: [Float], bufferSize: Int) -> Float {
        var sum: Float = 0.0
        for index in 0..<bufferSize {
            sum += buffer[index] * buffer[index]
        }
        return sqrtf(sum / Float(bufferSize))
    }
    
    static func time(from interval: TimeInterval) -> Time {
        let seconds = Int(interval.truncatingRemainder(dividingBy: 3600)
                            .truncatingRemainder(dividingBy: 60))
        let minutes = Int(interval.truncatingRemainder(dividingBy: 3600) / 60)
        let hours = Int(interval / 3600)
        let milliSeconds = Int((interval - TimeInterval(Int(interval))) * 100)
        let time = Time(hours: hours, minutes: minutes, seconds: seconds, milliSeconds: milliSeconds, interval: interval)
        
        return time
    }
}

// MARK: - AudioStreamBasicDescription

extension AudioUtils {
    static func floatFormat(with channels: UInt32, and sampleRate: Double) -> AudioStreamBasicDescription {
        var audioFormat = AudioStreamBasicDescription()
        let floatByteSize: UInt32 = 4
        audioFormat.mBitsPerChannel = 8 * floatByteSize
        audioFormat.mBytesPerFrame = floatByteSize
        audioFormat.mBytesPerPacket = floatByteSize
        audioFormat.mChannelsPerFrame = channels
        audioFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mFramesPerPacket = 1
        audioFormat.mSampleRate = sampleRate
        return audioFormat
    }

    static func stereoFloatNonInterleavedFormat(with sampleRate: Double) -> AudioStreamBasicDescription {
        var audioFormat = AudioStreamBasicDescription()
        let floatByteSize: UInt32 = 4
        audioFormat.mBitsPerChannel = 8 * floatByteSize;
        audioFormat.mBytesPerFrame = floatByteSize;
        audioFormat.mChannelsPerFrame = 2;
        audioFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
        audioFormat.mFormatID = kAudioFormatLinearPCM;
        audioFormat.mFramesPerPacket = 1;
        audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
        audioFormat.mSampleRate = sampleRate;
        return audioFormat;
    }

    static func monoFloatNonInterleavedFormat(with sampleRate: Double) -> AudioStreamBasicDescription {
        var audioFormat = AudioStreamBasicDescription()
        let floatByteSize: UInt32 = 4
        audioFormat.mBitsPerChannel = 8 * floatByteSize;
        audioFormat.mBytesPerFrame = floatByteSize;
        audioFormat.mChannelsPerFrame = 1;
        audioFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
        audioFormat.mFormatID = kAudioFormatLinearPCM;
        audioFormat.mFramesPerPacket = 1;
        audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
        audioFormat.mSampleRate = sampleRate;
        return audioFormat;
    }
}

// MARK: - AudioComponentDescription

extension AudioUtils {
    static func basicMicrophoneComponentDescription() -> AudioComponentDescription {
        var audioComponentDescription = AudioComponentDescription()
        audioComponentDescription.componentType = kAudioUnitType_Output
        audioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple
        audioComponentDescription.componentFlags = 0
        audioComponentDescription.componentFlagsMask = 0
        return audioComponentDescription
    }
}
