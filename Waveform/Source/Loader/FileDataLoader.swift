//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import AudioToolbox

class FileDataLoader {

    // MARK: - Private properties

    private let fileURL: URL
    private var fileReference: ExtAudioFileRef?
    private var audioFormat = AudioUtils.monoFloatNonInterleavedFormat(with: AudioUtils.defualtSampleRate)
    private var fileLengthInFrames: Int?
    
    // MARK: - Public properties
    
    var fileDuration: TimeInterval!

    // MARK: - Initialization

    init(fileURL: URL) throws {
        self.fileURL = fileURL
        
        try setup()
    }
    
    convenience init(fileName: String, fileFormat: String) throws {
        guard let filePathString = Bundle.main.path(forResource: fileName, ofType: fileFormat),
            let url = URL(string: filePathString) else {
                throw FileDataLoaderError.pathOrFormatProvidedInvalid
        }
        
        try self.init(fileURL: url)
    }
    
    // MARK: - Private methods
    
    private func setup() throws {
        try openFile(with: fileURL)
    }
    
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
            throw FileDataLoaderError.retriveFileLenghtFailed
        }
        return fileLengthInFrames
    }

    // MARK: - Access methods
    
    func loadFile(completion: (_ fileFloatArray: [Float]) -> Void) throws {
        //        let totalFrames = UInt32(duration * defaultFormat.mSampleRate)
        
        
        let numberOfPoints = WaveformConfiguration.microphoneSamplePerSecond * Int(fileDuration)
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
}
