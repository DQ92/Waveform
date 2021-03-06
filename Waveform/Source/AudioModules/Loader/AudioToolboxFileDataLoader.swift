//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation

class AudioToolboxFileDataLoader: FileDataLoaderProtocol {

    // MARK: - Public properties
    
    var duration: TimeInterval = 0.0
    
    // MARK: - Private properties

    private var fileReference: ExtAudioFileRef?
    private var audioFormat = AudioUtils.monoFloatNonInterleavedFormat(with: AudioUtils.defaultSampleRate)
    private var fileLengthInFrames: Int?

    // MARK: - Access methods

    func loadFile(with fileName: String,
                  and fileFormat: String,
                  completion: (_ fileFloatArray: [Float], _ duration: TimeInterval) -> Void) throws {
        guard let filePathString = Bundle.main.path(forResource: fileName, ofType: fileFormat),
              let url = URL(string: filePathString) else {
            throw FileDataLoaderError.pathOrFormatProvidedInvalid
        }
        try loadFile(with: url, completion: completion)
    }
    
    func loadFile(with URL: URL, completion: (_ fileFloatArray: [Float], _ duration: TimeInterval) -> Void) throws {
        try openFile(with: URL)
        let fileLengthInFrames = try getFileLengthInFrames(for: fileReference!)
        self.fileLengthInFrames = fileLengthInFrames
        if ExtAudioFileSetProperty(fileReference!,
                                   kExtAudioFileProperty_ClientDataFormat,
                                   UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
                                   &audioFormat) != noErr {
            throw FileDataLoaderError.setFormatFailed
        }
        self.duration = TimeInterval(fileLengthInFrames) / audioFormat.mSampleRate
        let numberOfPoints = Int(Double(WaveformConfiguration.microphoneSamplePerSecond) * duration)
        let framesPerBuffer = UInt32(fileLengthInFrames / numberOfPoints)
        let dataSize = UInt32(fileLengthInFrames) * audioFormat.mBytesPerFrame
        let theData = UnsafeMutablePointer<Float>.allocate(capacity: Int(dataSize))
        var bufferList: AudioBufferList = AudioBufferList()
        bufferList.mNumberBuffers = 1
        bufferList.mBuffers.mDataByteSize = dataSize
        bufferList.mBuffers.mNumberChannels = audioFormat.mChannelsPerFrame
        bufferList.mBuffers.mData = UnsafeMutableRawPointer(theData)
        var rmss: [Float] = []
        for _ in 0..<numberOfPoints {
            var bufferSize = UInt32(framesPerBuffer)
            if ExtAudioFileRead(fileReference!,
                                &bufferSize,
                                &bufferList) != noErr {
                throw FileDataLoaderError.fileReadFailed
            }
            var monoSamples = [Float]()
            let ptr = bufferList.mBuffers.mData?
                                         .assumingMemoryBound(to: Float.self)
            monoSamples.append(contentsOf: UnsafeBufferPointer(start: ptr,
                                                               count: Int(bufferSize)))
            let rms = AudioUtils.toRMS(buffer: monoSamples,
                                       bufferSize: Int(bufferSize))
            rmss.append(rms * AudioUtils.defaultWaveformFloatModifier)
        }
        completion(rmss, self.duration)
    }

    
    // MARK: - Private methods

    private func openFile(with fileURL: URL) throws {
        guard let sourceUrl = fileURL as CFURL? else {
            throw FileDataLoaderError.providedURLNotAcceptable
        }
        if ExtAudioFileOpenURL(sourceUrl, &fileReference) != noErr {
            throw FileDataLoaderError.openUrlFailed
        }
    }

    private func getFileLengthInFrames(for fileReference: ExtAudioFileRef) throws -> Int {
        var fileLengthInFrames: Int = 0
        var thePropertySize = UInt32(MemoryLayout.stride(ofValue: fileLengthInFrames))
        if ExtAudioFileGetProperty(fileReference,
                                   kExtAudioFileProperty_FileLengthFrames,
                                   &thePropertySize,
                                   &fileLengthInFrames) != noErr {
            throw FileDataLoaderError.retrieveFileLengthFailed
        }
        return fileLengthInFrames
    }
}
