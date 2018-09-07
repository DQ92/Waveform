import AVFoundation
import UIKit


class ViewController: UIViewController, AVAudioRecorderDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet var recordingTimeLabel: UILabel!
    @IBOutlet var record_btn_ref: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var waveformPlot: WaveformPlot!
    
    // MARK: - Private Properties
    
    let tempDictName = "temp_audio"
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let tempDirectoryURL = FileManager.default.temporaryDirectory;
    let libraryDirectoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory,
                                                       in: .userDomainMask).first!
    
    var values = [[WaveformModel]]() {
        didSet {
            self.waveformPlot.waveformView.values = values
        }
    }
    var audioRecorder: AVAudioRecorder!
    var meterTimer: Timer!
    var isAudioRecordingGranted: Bool = true
    var sampleIndex = 0 {
        didSet {
            self.waveformPlot.waveformView.sampleIndex = sampleIndex
        }
    }
    var sec: Int = 0
    private var elementsPerSecond: Int {
        return WaveformConfiguration.numberOfSamplesPerSecond(inViewWithWidth: UIScreen.main.bounds.width)
    }
    
    var numberOfRecord = 0
    var isRecording = false {
        didSet {
            self.waveformPlot.waveformView.isRecording = isRecording
            if (isRecording) {
                if let currentIndex = self.currentIndex, (currentIndex < sampleIndex) {
                    CATransaction.begin()
                    numberOfRecord = numberOfRecord + 1
                    sampleIndex = currentIndex
                    self.waveformPlot.waveformView.refresh()
                    CATransaction.commit()
                }
                self.waveformPlot.waveformView.isUserInteractionEnabled = false
            } else {
                self.waveformPlot.waveformView.isUserInteractionEnabled = true
                self.waveformPlot.waveformView.onPause(sampleIndex: CGFloat(sampleIndex))
            }
        }
    }
    var currentIndex: Int?
    var suffix: Int = 0
    let fileManager = FileManager.default
    var isMovedWhenPaused: Bool = false // gdy przesunie seek bara to ustawić na true
    var totalDuration: Float = 0
    var currentDuration: Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        removeTempDict()
//        createDictInTemp()
        
        self.waveformPlot.waveformView.delegate = self
        self.waveformPlot.waveformView.leadingLineTimeUpdaterDelegate = self
        
        AudioController.sharedInstance.prepare(specifiedSampleRate: 16000)
        AudioController.sharedInstance.delegate = self
//                printFloatDataFromAudioFile()
    }
}


//MARK - buttons - start/pause/resume
extension ViewController {
    @IBAction func startRecording(_ sender: UIButton) {
        startOrPause()
    }
    
    func startOrPause() {
        if (isRecording) {
            pause()
        } else if (isMovedWhenPaused) {
            stop()
        } else {
            if let curTime = audioRecorder?.currentTime, curTime > TimeInterval(0.1) {
                resume()
            } else {
                startRecording()
            }
        }
    }
    
    func stop() {
        log("stopped")
        AudioController.sharedInstance.stop()
        isMovedWhenPaused = false
        record_btn_ref.setTitle("Start", for: .normal)
        isRecording = false
        audioRecorder?.stop()
        meterTimer.invalidate()
        audioRecorder = nil
        log("recorded successfully.")
        listFiles()
        _ = getAllAudioParts()
    }
    
    func resume() {
        AudioController.sharedInstance.start()
        log("Resumed")
        isRecording = true
        
        record_btn_ref.setTitle("Pause", for: .normal)
        audioRecorder.record()
    }
    
    func pause() {
        log("Paused")
        AudioController.sharedInstance.stop()
        record_btn_ref.setTitle("Resume", for: .normal)
        isRecording = false
        audioRecorder.pause()
        listFiles()
        
        _ = getAllAudioParts()
    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        stop()
        merge(assets: getAllAudioParts())
    }
    
    func createModel(value: CGFloat, with timeStamp: TimeInterval) -> WaveformModel {
        return WaveformModel(value: value, numberOfRecord: numberOfRecord, timeStamp: timeStamp)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AudioFilesListViewController {
            viewController.directoryUrl = self.documentsURL.appendingPathComponent(self.tempDictName)
            viewController.didSelectFileBlock = { [weak self] url in
                let successHandler: (AudioContext) -> (Void) = { context in
                    let samples = context.extractSamples()
                    let values = self?.buildWaveformModel(from: samples, numberOfSeconds: context.numberOfSeconds)

                    DispatchQueue.main.async {
                        self?.waveformPlot.waveformView.load(values: values ?? [])
                    }
                    
                }
                let failureHandler: (Error) -> (Void) = { [weak self] error in
                    let alertController = UIAlertController(title: "Błąd",
                                                            message: error.localizedDescription,
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self?.present(alertController, animated: true)
                }
                
                AudioContext.loadAudio(from: url, successHandler: successHandler, failureHandler: failureHandler)
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func buildWaveformModel(from samples: [Float], numberOfSeconds: Double) -> [[WaveformModel]] {
        // Liczba próbek na sekundę
        let sampleRate = Double(samples.count) / numberOfSeconds
        let waveformSamples = samples.enumerated().map { sample in
            WaveformModel(value: CGFloat(sample.element), numberOfRecord: 0, timeStamp: Double(sample.offset) / sampleRate)
        }
        
        // Po wczytaniu z pliku wykres ma się mieścić cały na ekranie. (domyślnie mieści się 6 komórek)
//        let numberOfCellsPerScreen: Int = 6
//        let samplesPerCell = Int(ceil(Float(samples.count) / Float(numberOfCellsPerScreen)))
        
        let samplesPerCell = Int(ceil(Float(samples.count) / Float(numberOfSeconds)))
        
        var result = [[WaveformModel]]()
        
        for cellIndex in 0..<Int(numberOfSeconds) {
            let beginIndex = cellIndex * samplesPerCell
            let endIndex = min(beginIndex + samplesPerCell, waveformSamples.count)
            var cellSamples = [WaveformModel]()
            
            for index in beginIndex..<endIndex {
                cellSamples.append(waveformSamples[index])
            }
            result.append(cellSamples)
        }
        return result
    }
}

// MARK: - buttons - start/pause/resume
extension ViewController {
    @objc func updateAudioMeter(timer: Timer) {
        //
    }
    
    func updatePeak(_ peak: Float, with timeStamp: TimeInterval) {
        sampleIndex = sampleIndex + 1
        let _peak: Float = peak
        self.sec = Int(sampleIndex / elementsPerSecond) + 1
        
        Assert.checkRep(sec < 0, "Second value is less than 0!")
        
        //newsecon
        if values.count <= sec {
            newSecond()
        }
        
        let precision = sampleIndex % elementsPerSecond
        let model = createModel(value: CGFloat(_peak), with: timeStamp)
        if (values[sec - 1].count == elementsPerSecond) {
            values[sec - 1][precision] = model
        } else {
            values[sec - 1].append(model)
        }
        
        if (values[sec - 1].count > elementsPerSecond) {
            Assert.checkRep(true, "ERROR! values[sec - 1].count > elementsPerSecond")
        }
        self.waveformPlot.waveformView.update(model: model, sampleIndex: sampleIndex)
    }
    
    func newSecond() {
        values.append([])
        self.waveformPlot.waveformView.newSecond(values.count - 1, CGFloat(sampleIndex))
    }
}

// MARK: - WaveformViewDelegate

extension ViewController: WaveformViewDelegate {
    
    func didScroll(_ x: CGFloat) {
        if (!self.isRecording) {
            currentIndex = Int(x)
        }
    }
}

extension ViewController: LeadingLineTimeUpdaterDelegate {
    func timeDidChange(with time: Time) {
        let totalTimeString = String(format: "%02d:%02d:%02d:%02d", time.hours, time.minutes, time.seconds, time.milliSeconds)
        timeLabel.text = totalTimeString
    }
}

extension ViewController: AudioControllerDelegate {
    func processSampleData(_ data: Float) {
        updatePeak(data * 100 * 3, with: audioRecorder.currentTime)
    }
}

// MARK: - File loading

extension ViewController {

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
        
        let model = buildWaveformModel(from: rmss, numberOfSeconds: duration)
        self.waveformPlot.waveformView.load(values: model)
    }
}
