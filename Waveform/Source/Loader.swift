//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation
import AudioToolbox

class Loader {
    func printFloatDataFromAudioFile() {
        let name = "rec_1"
        let source = URL(string: Bundle.main.path(forResource: name, ofType: "m4a")!)! as CFURL

        var fileRef: ExtAudioFileRef?
        ExtAudioFileOpenURL(source, &fileRef)

        let floatByteSize: UInt32 = 4
        let channels: UInt32 = 1

        var audioFormat = AudioStreamBasicDescription()
        audioFormat.mBitsPerChannel = 8 * floatByteSize
        audioFormat.mBytesPerFrame = floatByteSize
        audioFormat.mChannelsPerFrame = channels
        audioFormat.mSampleRate = 44100
        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved
        audioFormat.mFramesPerPacket = 1
        audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;

        ExtAudioFileSetProperty(fileRef!,
                kExtAudioFileProperty_ClientDataFormat,
                UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
                &audioFormat)

        var theFileLengthInFrames: Int64 = 0
        var thePropertySize = UInt32(MemoryLayout.stride(ofValue: theFileLengthInFrames))
        ExtAudioFileGetProperty(fileRef!,
                kExtAudioFileProperty_FileLengthFrames,
                &thePropertySize,
                &theFileLengthInFrames)



        let duration: TimeInterval = Double(theFileLengthInFrames) / audioFormat.mSampleRate
        let totalFrames = UInt32(duration * audioFormat.mSampleRate)
        let framesPerBuffer: UInt32 = 62
//        let framesPerBuffer = UInt32(totalFrames / 1024)

        let dataSize = UInt32(theFileLengthInFrames) * audioFormat.mBytesPerFrame

        let theData = UnsafeMutablePointer<Float>.allocate(capacity: Int(dataSize))
        var bufferList: AudioBufferList = AudioBufferList()
        bufferList.mNumberBuffers = 1
        bufferList.mBuffers.mDataByteSize = dataSize
        bufferList.mBuffers.mNumberChannels = audioFormat.mChannelsPerFrame
        bufferList.mBuffers.mData = UnsafeMutableRawPointer(theData)

        var rmss: [Float] = []
        let numberOfSamples = Int(62.0 * duration)

        for _ in 0..<numberOfSamples {

            var bufferSize = UInt32(framesPerBuffer)

            ExtAudioFileRead(fileRef!,
                    &bufferSize,
                    &bufferList)


            var monoSamples = [Float]()
            let ptr = bufferList.mBuffers.mData?.assumingMemoryBound(to: Float.self)
            monoSamples.append(contentsOf: UnsafeBufferPointer(start: ptr, count: Int(bufferSize)))

            let rms = AudioUtils.toRMS(buffer: monoSamples, bufferSize: Int(bufferSize))
            rmss.append(rms * 100 * 3)
        }

//        let model = buildWaveformModel(from: rmss, numberOfSeconds: duration)
//        waveformCollectionView.load(values: model)
    }
}
