

import Foundation
import AVFoundation

class AVFoundationMicrophoneController {

    // MARK: - Private properties

    // MARK: - Public properties

    var delegate: MicrophoneControllerDelegate!
    static let shared = AVFoundationMicrophoneController()
    // Optional is needed for inout parameter
    var remoteIOUnit: AudioComponentInstance?


    // MARK: - Initialization

    private init() {
        setup()
    }

    // MARK: - Deinitialization

    deinit {
        AudioComponentInstanceDispose(remoteIOUnit!);
    }

    // MARK: - Setup

    private func setup() {
        var audioComponentDescription = AudioComponentDescription()
        audioComponentDescription.componentType = kAudioUnitType_Output;
        audioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO;
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
        audioComponentDescription.componentFlags = 0;
        audioComponentDescription.componentFlagsMask = 0;

        let remoteIOComponent = AudioComponentFindNext(nil, &audioComponentDescription)
        var status = AudioComponentInstanceNew(remoteIOComponent!, &remoteIOUnit)
        if (status != noErr) {
            assertionFailure("Initialization failed")
        }

        let bus: AudioUnitElement = 1
        var oneFlag: UInt32 = 1

        // Configure the RemoteIO unit for input
        status = AudioUnitSetProperty(remoteIOUnit!,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Input,
                                      bus,
                                      &oneFlag,
                                      UInt32(MemoryLayout<UInt32>.size));
        if (status != noErr) {
            assertionFailure("Initialization failed")
        }

        let sampleRate: Double = AVAudioSession.sharedInstance().sampleRate
        let channels: UInt32 = 1
        var audioFormat = AudioUtils.floatFormat(with: channels, and: sampleRate)

        status = AudioUnitSetProperty(remoteIOUnit!,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Output,
                                      bus,
                                      &audioFormat,
                                      UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        if (status != noErr) {
            assertionFailure("Initialization failed")
        }

        // Set the recording callback
        var callbackStruct = AURenderCallbackStruct()
        callbackStruct.inputProc = recordingCallback
        callbackStruct.inputProcRefCon = nil
        status = AudioUnitSetProperty(remoteIOUnit!,
                                      kAudioOutputUnitProperty_SetInputCallback,
                                      kAudioUnitScope_Global,
                                      bus,
                                      &callbackStruct,
                                      UInt32(MemoryLayout<AURenderCallbackStruct>.size));
        if (status != noErr) {
            assertionFailure("Initialization failed")
        }

        // Initialize the RemoteIO unit

        status = AudioUnitInitialize(remoteIOUnit!)
        if (status != noErr) {
            assertionFailure("Initialization failed")
        }
    }

    // MARK: - Access methods

    func start() {
        let status = AudioOutputUnitStart(remoteIOUnit!)
        if status != noErr {
            assertionFailure("Microphone data retrieving start failed")
        }
    }

    func stop() {
        let status = AudioOutputUnitStop(remoteIOUnit!)
        if status != noErr {
            assertionFailure("Microphone data retrieving start failed")
        }
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
    status = AudioUnitRender(AVFoundationMicrophoneController.shared.remoteIOUnit!,
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
        AVFoundationMicrophoneController.shared.delegate.processSampleData(rms)
    }

    return noErr
}
