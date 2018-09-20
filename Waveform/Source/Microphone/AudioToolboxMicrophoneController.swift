import Foundation
import AudioToolbox

class AudioToolboxMicrophoneController {

    // MARK: - Private properties

    // Optional is needed for inout parameter
    fileprivate var remoteIOUnit: AudioComponentInstance?

    // MARK: - Public properties

    var delegate: MicrophoneControllerDelegate!
    static let shared = AudioToolboxMicrophoneController()

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
        var audioComponentDescription = AudioUtils.basicMicrophoneComponentDescription()
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

        let sampleRate: Double = AudioUtils.defaultSampleRate
        let channelCount: UInt32 = 2
        var audioFormat = AudioUtils.floatFormat(with: channelCount, and: sampleRate)

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
            assertionFailure("Microphone data retrieving stop failed")
        }
    }
}

func recordingCallback(inRefCon: UnsafeMutableRawPointer,
                       ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                       inTimeStamp: UnsafePointer<AudioTimeStamp>,
                       inBusNumber: UInt32,
                       inNumberFrames: UInt32,
                       ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {

    var status = noErr
    let channelCount: UInt32 = 2
    var bufferList = AudioBufferList()
    bufferList.mNumberBuffers = channelCount
    let buffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &bufferList.mBuffers,
                                                          count: Int(bufferList.mNumberBuffers))
    buffers[0].mNumberChannels = channelCount
    buffers[0].mDataByteSize = inNumberFrames * 2
    buffers[0].mData = nil

    // get the recorded samples
    status = AudioUnitRender(AudioToolboxMicrophoneController.shared.remoteIOUnit!,
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
        AudioToolboxMicrophoneController.shared.delegate.processSampleData(rms)
    }

    return noErr
}
