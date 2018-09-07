

import Foundation
import AVFoundation

protocol AudioControllerDelegate {
    func processSampleData(_ data: Float) -> Void
}

class AudioController { // TODO: przerobic
    var remoteIOUnit: AudioComponentInstance? // optional to allow it to be an inout argument
    var delegate: AudioControllerDelegate!

    static var sharedInstance = AudioController()

    deinit {
        AudioComponentInstanceDispose(remoteIOUnit!);
    }

    func prepare(with sampleRate: Double) -> OSStatus {

        // Describe the RemoteIO unit
        var audioComponentDescription = AudioComponentDescription()
        audioComponentDescription.componentType = kAudioUnitType_Output;
        audioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO;
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
        audioComponentDescription.componentFlags = 0;
        audioComponentDescription.componentFlagsMask = 0;

        // Get the RemoteIO unit
        let remoteIOComponent = AudioComponentFindNext(nil, &audioComponentDescription)
        var status = AudioComponentInstanceNew(remoteIOComponent!, &remoteIOUnit)
        if (status != noErr) {
            return status
        }

        let bus1: AudioUnitElement = 1
        var oneFlag: UInt32 = 1

        // Configure the RemoteIO unit for input
        status = AudioUnitSetProperty(remoteIOUnit!,
                kAudioOutputUnitProperty_EnableIO,
                kAudioUnitScope_Input,
                bus1,
                &oneFlag,
                UInt32(MemoryLayout<UInt32>.size));
        if (status != noErr) {
            return status
        }

        let sampleRate: Double = 44100
        let channels: UInt32 = 1
        var audioFormat = AudioUtils.floatFormat(with: channels, with: sampleRate)

        status = AudioUnitSetProperty(remoteIOUnit!,
                kAudioUnitProperty_StreamFormat,
                kAudioUnitScope_Output,
                bus1,
                &audioFormat,
                UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        if (status != noErr) {
            return status
        }

        // Set the recording callback
        var callbackStruct = AURenderCallbackStruct()
        callbackStruct.inputProc = recordingCallback
        callbackStruct.inputProcRefCon = nil
        status = AudioUnitSetProperty(remoteIOUnit!,
                kAudioOutputUnitProperty_SetInputCallback,
                kAudioUnitScope_Global,
                bus1,
                &callbackStruct,
                UInt32(MemoryLayout<AURenderCallbackStruct>.size));
        if (status != noErr) {
            return status
        }

        // Initialize the RemoteIO unit
        return AudioUnitInitialize(remoteIOUnit!)
    }

    func start() -> OSStatus {
        return AudioOutputUnitStart(remoteIOUnit!)
    }

    func stop() -> OSStatus {
        return AudioOutputUnitStop(remoteIOUnit!)
    }
}

func recordingCallback(
        inRefCon: UnsafeMutableRawPointer,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBusNumber: UInt32,
        inNumberFrames: UInt32,
        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {

    var status = noErr

    let channelCount: UInt32 = 1

    var bufferList = AudioBufferList()
    bufferList.mNumberBuffers = channelCount
    let buffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &bufferList.mBuffers,
            count: Int(bufferList.mNumberBuffers))
    buffers[0].mNumberChannels = channelCount
    buffers[0].mDataByteSize = inNumberFrames * 2
    buffers[0].mData = nil

    // get the recorded samples
    status = AudioUnitRender(AudioController.sharedInstance.remoteIOUnit!,
            ioActionFlags,
            inTimeStamp,
            inBusNumber,
            inNumberFrames,
            UnsafeMutablePointer<AudioBufferList>(&bufferList))
    if (status != noErr) {
        return status;
    }
    
    var monoSamples = [Float]()
    let ptr = bufferList.mBuffers.mData?.assumingMemoryBound(to: Float.self)
    monoSamples.append(contentsOf: UnsafeBufferPointer(start: ptr, count: Int(inNumberFrames)))

    let rms = AudioUtils.toRMS(buffer: monoSamples, bufferSize: 512)
    
    
    DispatchQueue.main.async {
        AudioController.sharedInstance.delegate.processSampleData(rms)
    }

    return noErr
}
