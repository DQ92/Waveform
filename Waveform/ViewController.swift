import AVFoundation
import UIKit

let timeInterval: TimeInterval = (TimeInterval(6 / Float(UIScreen.main.bounds.width)))
var viewWidth: CGFloat = 0
var partOfView: CGFloat = 0 // 1/6

class ViewController: UIViewController, AVAudioRecorderDelegate {

    // MARK: - IBOutlets

    @IBOutlet var recordingTimeLabel: UILabel!
    @IBOutlet var record_btn_ref: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var waveform: WaveformViewScroll!
    @IBOutlet weak var waveformRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewWaveform: WaveformView!
    @IBOutlet weak var collectionViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var timerLabel: UILabel!

    // MARK: - Private Properties

    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let tempDirectoryURL = FileManager.default.temporaryDirectory;
    private let libraryDirectoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory,
                                                               in: .userDomainMask).first!

    var values = [[WaveformModel]]() {
        didSet {
            collectionViewWaveform.values = values
        }
    }
    
    let vLayer = CAShapeLayer()
    let max: Float = 120
    var audioRecorder: AVAudioRecorder!
    var meterTimer: Timer!
    var isAudioRecordingGranted: Bool = true
    var sampleIndex = 0 {
        didSet {
            collectionViewWaveform.sampleIndex = sampleIndex
        }
    }
    var sec: Int = 0 {
        didSet {
            if (sec != oldValue) {
                newSecond()
            }
        }
    }
    var leadingLineX: CGFloat = 0
    let padding: CGFloat = 0
    private var elementsPerSecond: Int {
        return Int((UIScreen.main.bounds.width) / 6)
    }

    var part = 0
    var isRecording = false {
        didSet {
            collectionViewWaveform.isRecording = isRecording

            if (isRecording) {
                if(currentIndex < sampleIndex) {
                    CATransaction.begin()
                    part = part + 1
                    sampleIndex = currentIndex
                    collectionViewWaveform.values = values
                    collectionViewWaveform.refresh()
                    CATransaction.commit()
                }
                collectionViewWaveform.isUserInteractionEnabled = false
            } else {
                collectionViewWaveform.isUserInteractionEnabled = true
                collectionViewWaveform.onPause(sampleIndex: CGFloat(sampleIndex))
            }
        }
    }
    var currentIndex: Int = 0
    var suffix: Int = 0
    private let tempDictName = "temp_audio"
    let fileManager = FileManager.default
    var isMovedWhenPaused: Bool = false // gdy przesunie seek bara to ustawić na true
    var totalDuration: Float = 0 {
        didSet {
            totalTimeLabel.text = "\(totalDuration + currentDuration) sec."
        }
    }
    var currentDuration: Float = 0
    private let preferredTimescale: CMTimeScale = 1000

    override func viewDidLoad() {
        super.viewDidLoad()

        removeTempDict()
        createDictInTemp()

        viewWidth = UIScreen.main.bounds.width
        partOfView = viewWidth / 6
        
        collectionViewWaveform.delegate = self
    }

    func listFiles() {
        list(directory: documentsURL.appendingPathComponent(tempDictName))
    }

    func getFileUrl() -> URL {
        let filename = "rec_\(suffix).m4a"
        let dict = documentsURL.appendingPathComponent(tempDictName)
        let filePath = dict.appendingPathComponent(filename)
        return filePath
    }

    func removeTempDict() {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(tempDictName)")
        do {
            try fileManager.removeItem(at: dictPath)
        } catch {
            log("Couldn't removeItem \(dictPath)")
        }
    }

    func createDictInTemp() {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(tempDictName)")
        if !fileManager.fileExists(atPath: dictPath.path) {
            do {
                try fileManager.createDirectory(atPath: dictPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                log("Couldn't create document directory")
            }
        }
        log("Document directory is \(dictPath)")
    }

    func log(_ val: Any) {
        print(val)
    }

    @IBAction func sliderDidChanged(_ sender: UISlider) {
        isMovedWhenPaused = true
    }

    func getAllAudioParts() -> [AVAsset] {
        let at = documentsURL.appendingPathComponent(tempDictName)
        var listing = try! FileManager.default.contentsOfDirectory(atPath: at.path)
        var assets = [AVAsset]()
        listing = listing.sorted(by: { $0 < $1 })
        totalDuration = 0

        for file in listing {
            let fileURL = at.appendingPathComponent(file)
            print("FILE URL: \(fileURL)")
            let asset = AVAsset(url: fileURL)
            totalDuration += assetDuration(asset)
            assets.append(asset)
        }

        slider.maximumValue = totalDuration + currentDuration
        log("slider.maximumValue: \(slider.maximumValue)")
        return assets
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
        log("Resumed")
        isRecording = true
        
        record_btn_ref.setTitle("Pause", for: .normal)
        audioRecorder.record()
    }

    func pause() {
        log("Paused")
        record_btn_ref.setTitle("Resume", for: .normal)
        isRecording = false
        audioRecorder.pause()
        listFiles()

        _ = getAllAudioParts()
    }

    func startRecording() {
        if isAudioRecordingGranted { //sprawdzać wcześniej!
            log("startRecording")
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                suffix = suffix + 1
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
                audioRecorder.record()
                meterTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.updateAudioMeter(timer:)), userInfo: nil, repeats: true) //zatrzymywać timer na pauzie

                record_btn_ref.setTitle("Pause", for: .normal)
                isRecording = true
            } catch let error {
                log("\(error.localizedDescription)")
            }
        } else {
            log("Don't have access to use your microphone.")
        }
    }

    @IBAction func finishButtonTapped(_ sender: Any) {
        stop()
        merge(assets: getAllAudioParts())
    }
    
    func createModel(value: CGFloat) -> WaveformModel {
        return WaveformModel(value: value, part: part)
    }
}

//MARK - buttons - start/pause/resume
extension ViewController {

    @objc func updateAudioMeter(timer: Timer) {
        if audioRecorder.isRecording {
            let hr = Int((audioRecorder.currentTime / 60) / 60)
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
            let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
            recordingTimeLabel.text = totalTimeString
            currentDuration = Float(sec)
            let t = totalDuration + currentDuration
            totalTimeLabel.text = "\(t) sec."
            audioRecorder.updateMeters()
            let peak = audioRecorder.averagePower(forChannel: 0) - 60
            updatePeak(peak)
            sampleIndex = sampleIndex + 1
        }
    }

    func updatePeak(_ peak: Float) {
        let _peak: Float = (-1) * peak
        var value: Float = max - _peak
        value = value > 1 ? value : 4

        self.sec = Int(sampleIndex / elementsPerSecond) + 1
        let model = createModel(value: CGFloat(value))
//        values[values.count - 1].append(model)
        if(values[sec - 1].count == elementsPerSecond) {
            values[sec - 1].insert(model, at: (sampleIndex % elementsPerSecond))
        } else {
            values[sec - 1].append(model)
        }
        
        collectionViewWaveform.values = values
        collectionViewWaveform.update(model: model, sampleIndex: sampleIndex)
    }

    @IBAction func recordAt(_ sender: UIButton) {
        stop()

        let time: TimeInterval = TimeInterval(slider.value);
        sender.setTitle("Crop at... \(time) sec", for: .normal)
        crop(sourceURL: getFileUrl(), startTime: 0, endTime: time) { (url) in
            self.suffix = self.suffix + 1
        }
    }

    func crop(sourceURL: URL, startTime: Double, endTime: Double, completion: ((_ outputUrl: URL) -> Void)? = nil) {
        let asset = AVAsset(url: sourceURL)
        let length = assetDuration(asset)
        log("length asset to crop: \(length) seconds")

        if (endTime > Double(length)) {
            log("Error! endTime > length")
        }

        var outputURL = documentsURL.appendingPathComponent(tempDictName)
        do {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
        } catch let error {
            log(error)
        }

        let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: self.preferredTimescale), end: CMTime(seconds: endTime, preferredTimescale: self.preferredTimescale))

        try? fileManager.removeItem(at: outputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously {
            switch exportSession.status {
                case .completed:
                    self.log("CROPPED exported at \(outputURL)")
                    completion?(outputURL)
                case .failed:
                    self.log("failed \(exportSession.error.debugDescription)")
                case .cancelled:
                    self.log("cancelled \(exportSession.error.debugDescription)")
                default: break
            }
        }
    }

    func merge(assets: [AVAsset]) {
        let at = documentsURL.appendingPathComponent(tempDictName)

        if assets.count > 1 {
            print("\n----------------------------")
            print("MERGE: \(at.path)")

            var atTimeM: CMTime = kCMTimeZero
            let composition: AVMutableComposition = AVMutableComposition()
            var totalTime: CMTime = kCMTimeZero
            let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

            for asset in assets {
                do {
                    if asset == assets.first {
                        atTimeM = kCMTimeZero
                    } else {
                        atTimeM = totalTime // <-- Use the total time for all the audio so far.
                    }

                    log("Total Time: \(totalTime)")
                    if let track = asset.tracks(withMediaType: AVMediaType.audio).first {

                        try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration),
                                                       of: track,
                                                       at: atTimeM)
                        totalTime = CMTimeAdd(totalTime, asset.duration)
                    } else {
                        log("error!!")
                    }
                } catch let error as NSError {
                    log("error while merging: \(error)")
                }
            }

            let finalURL = at.appendingPathComponent("result.m4a")
            log("EXPORTING MERGE....\(finalURL)")

            if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
                exportSession.outputURL = finalURL
                exportSession.outputFileType = .mp4
                exportSession.exportAsynchronously {
                    switch exportSession.status {
                        case .completed:
                            print("exported at \(finalURL)")
                        case .failed:
                            print("failed \(exportSession.error.debugDescription)")
                        case .cancelled:
                            print("cancelled \(exportSession.error.debugDescription)")
                        default: break
                    }
                }
            }
        } else {
            print("Brak plików w \(at.path)")
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        log("audioRecorderDidFinishRecording")
    }

    func assetDuration(_ asset: AVAsset) -> Float {
        return Float(asset.duration.value) / Float(asset.duration.timescale)
    }

    func list(directory at: URL) -> Void {
        let listing = try! FileManager.default.contentsOfDirectory(atPath: at.path)
        if listing.count > 0 {
            print("\n----------------------------")
            print("LISTING: \(at.path) \n")
            for file in listing {
                print("File: \(file.debugDescription)")
            }
            print("")
            print("----------------------------\n")
        } else {
            print("Brak plików w \(at.path)")
        }
    }

    func newSecond() {
        values.append([])
        collectionViewWaveform.values = values
  
        collectionViewWaveform.newSecond(values.count - 1, CGFloat(sampleIndex))
    }
}


// MARK: - WaveformViewDelegate
extension ViewController: WaveformViewDelegate {
    
    func didScroll(_ x: CGFloat, _ leadingLineX: CGFloat) {
        if(!self.isRecording) {
            currentIndex = Int(x)
            self.leadingLineX = x
            print("currentIndex: \(currentIndex)")
            
//            if let last = values.last?.last?.part {
//                print("BEFORE didScroll: \(String(describing: values.last?.last?.part))")
//                values.last!.last!.part = last + 1
//                print("AFTER didScroll: \(String(describing: values.last?.last?.part))")
//            }
        }
    }
}
