//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation

class AudioToolboxFileDataLoader: FileDataLoaderProtocol {

    // MARK: - Private properties

    private var fileReference: ExtAudioFileRef?
    private var audioFormat = AudioUtils.monoFloatNonInterleavedFormat(with: AudioUtils.defaultSampleRate)
    private var fileLengthInFrames: Int?
    
    var engine = AVAudioEngine()

    // MARK: - Public properties

    var fileDuration: TimeInterval!

    // MARK: - Access methods

    func loadFile(with fileName: String,
                  and fileFormat: String,
                  completion: (_ fileFloatArray: [Float]) -> Void) throws {
        guard let filePathString = Bundle.main.path(forResource: fileName, ofType: fileFormat),
              let url = URL(string: filePathString) else {
            throw FileDataLoaderError.pathOrFormatProvidedInvalid
        }
        try loadFile(with: url, completion: completion)
    }

//    func loadFile(with URL: URL, completion: (_ fileFloatArray: [Float]) -> Void) throws {
//        let settings = [
//            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//            AVSampleRateKey: 44100,
//            AVNumberOfChannelsKey: 1,
//            ]
//        let format = AVAudioFormat(settings: settings)
//        let file = try AVAudioFile(forWriting: URL, settings: settings)
//
//        try self.engine.start()
//
//
//
//        self.engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, when in
//
//        }
//    }
    
    func loadFile(with URL: URL, completion: (_ fileFloatArray: [Float]) -> Void) throws {
        try openFile(with: URL)
        let numberOfPoints = Int(Double(WaveformConfiguration.microphoneSamplePerSecond) * fileDuration)
        let framesPerBuffer = UInt32(fileLengthInFrames! / numberOfPoints)
        let dataSize = UInt32(fileLengthInFrames!) * audioFormat.mBytesPerFrame
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
        completion(rmss)
    }
    
    // MARK: - Private methods

    private func openFile(with fileURL: URL) throws {
        guard let sourceUrl = fileURL as CFURL? else {
            throw FileDataLoaderError.providedURLNotAcceptable
        }
        if ExtAudioFileOpenURL(sourceUrl, &fileReference) != noErr {
            throw FileDataLoaderError.openUrlFailed
        }
        let fileLengthInFrames = try getFileLengthInFrames(for: fileReference!)
        self.fileLengthInFrames = fileLengthInFrames
        if ExtAudioFileSetProperty(fileReference!,
                                   kExtAudioFileProperty_ClientDataFormat,
                                   UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
                                   &audioFormat) != noErr {
            throw FileDataLoaderError.setFormatFailed
        }
        let duration: TimeInterval = Double(fileLengthInFrames) / audioFormat.mSampleRate
        self.fileDuration = duration
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
