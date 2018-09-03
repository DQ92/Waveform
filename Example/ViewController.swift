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
    @IBOutlet weak var waveformCollectionView: WaveformView!
    @IBOutlet weak var collectionViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var timeLabel: UILabel!

    // MARK: - Private Properties

    let preferredTimescale: CMTimeScale = 1000
    let tempDictName = "temp_audio"
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let tempDirectoryURL = FileManager.default.temporaryDirectory;
    let libraryDirectoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory,
            in: .userDomainMask).first!

    var values = [[WaveformModel]]() {
        didSet {
            waveformCollectionView.values = values
        }
    }

    let vLayer = CAShapeLayer()
    let max: Float = 120
    var audioRecorder: AVAudioRecorder!
    var meterTimer: Timer!
    var isAudioRecordingGranted: Bool = true
    var sampleIndex = 0 {
        didSet {
            waveformCollectionView.sampleIndex = sampleIndex
        }
    }
    var sec: Int = 0

    let padding: CGFloat = 0
    private var elementsPerSecond: Int {
        return Int((UIScreen.main.bounds.width) / 6)
    }

    var part = 0
    var isRecording = false {
        didSet {
            waveformCollectionView.isRecording = isRecording
            if (isRecording) {
                if let currentIndex = self.currentIndex, (currentIndex < sampleIndex) {
                    CATransaction.begin()
                    part = part + 1
                    sampleIndex = currentIndex
                    waveformCollectionView.refresh()
                    CATransaction.commit()
                }
                waveformCollectionView.isUserInteractionEnabled = false
            } else {
                waveformCollectionView.isUserInteractionEnabled = true
                waveformCollectionView.onPause(sampleIndex: CGFloat(sampleIndex))
            }
        }
    }
    var currentIndex: Int?
    var suffix: Int = 0
    let fileManager = FileManager.default
    var isMovedWhenPaused: Bool = false // gdy przesunie seek bara to ustawić na true
    var totalDuration: Float = 0 {
        didSet {
            totalTimeLabel.text = "\(totalDuration + currentDuration) sec."
        }
    }
    var currentDuration: Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        removeTempDict()
        createDictInTemp()

        viewWidth = UIScreen.main.bounds.width
        partOfView = viewWidth / 6

        waveformCollectionView.delegate = self
        waveformCollectionView.leadingLineTimeUpdaterDelegate = self
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

    @IBAction func finishButtonTapped(_ sender: Any) {
        stop()
        merge(assets: getAllAudioParts())
    }

    func createModel(value: CGFloat, with timeStamp: TimeInterval) -> WaveformModel {
        return WaveformModel(value: value, part: part, timeStamp: timeStamp)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AudioFilesListViewController {
            viewController.directoryUrl = self.documentsURL.appendingPathComponent(self.tempDictName)
            viewController.didSelectFileBlock = { [weak self] url in
                let successHandler: (AudioContext) -> (Void) = { context in
                    
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
}

// MARK: - buttons - start/pause/resume

extension ViewController {
    @objc func updateAudioMeter(timer: Timer) {
        if isRecording {
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
            updatePeak(peak, with: audioRecorder.currentTime)
        }
    }

    func updatePeak(_ peak: Float, with timeStamp: TimeInterval) {
        sampleIndex = sampleIndex + 1

        let _peak: Float = (-1) * peak
        var value: Float = max - _peak
        value = value > 1 ? value : 4

        self.sec = Int(sampleIndex / elementsPerSecond) + 1

        //newsecon
        if values.count <= sec {
            newSecond()
        }

        let precision = sampleIndex % elementsPerSecond
        let model = createModel(value: CGFloat(value), with: timeStamp)
        if (values[sec - 1].count == elementsPerSecond) {
            values[sec - 1][precision] = model
        } else {
            values[sec - 1].append(model)
        }

        if (values[sec - 1].count > elementsPerSecond) {
            print("ERROR! values[sec - 1].count > elementsPerSecond")
        }
        waveformCollectionView.update(model: model, sampleIndex: sampleIndex)
    }

    func newSecond() {
        values.append([])
        waveformCollectionView.newSecond(values.count - 1, CGFloat(sampleIndex))
    }
}

// MARK: - WaveformViewDelegate

extension ViewController: WaveformViewDelegate {

    func didScroll(_ x: CGFloat) {
        if (!self.isRecording) {
            currentIndex = Int(x)
//            print("currentIndex: \(currentIndex)")
        }
    }
}

extension ViewController: LeadingLineTimeUpdaterDelegate {
    func timeDidChange(with time: Time) {
        let totalTimeString = String(format: "%02d:%02d:%02d:%02d", time.hours, time.minutes, time.seconds, time.milliSeconds)
        timeLabel.text = totalTimeString
    }
}
