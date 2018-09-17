import UIKit
import AVFoundation

class AddIllustrationsViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var recordingTimeLabel: UILabel!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var waveformWithIllustrationsPlot: WaveformWithIllustrationsPlot!
    @IBOutlet weak var playOrPauseButton: UIButton!
    
    // MARK: - Private Properties

    private var recorder: RecorderProtocol = AVFoundationRecorder()
    private var player: AudioPlayerProtocol = AVFoundationAudioPlayer()
    private var loader: FileDataLoader!
    private var url: URL!
    private var values = [[WaveformModel]]() {
        didSet {
            self.waveformWithIllustrationsPlot.waveformPlot.waveformView.values = values
        }
    }

    private var elementsPerSecond: Int {
        return WaveformConfiguration.microphoneSamplePerSecond
    }

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss:SS"

        return formatter
    }()

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupRecorder()
        setupWaveform()
        setupPlayer()
        setupAudioController()
    }

    private func setupView() {
        totalTimeLabel.text = "00:00:00"
        timeLabel.text = "00:00:00"
    }

    private func setupRecorder() {
        recorder.delegate = self
    }

    private func setupWaveform() {
        self.waveformWithIllustrationsPlot.delegate = self
    }

    private func setupPlayer() {
        self.player.delegate = self
    }

    private func setupAudioController() {
        AudioController.sharedInstance.prepare(with: AudioUtils.defualtSampleRate)
        AudioController.sharedInstance.delegate = self
    }
}

//extension AddIllustrationsViewController {
//    func setupScrollView(contentWidth: CGFloat) {
//        let constraint = NSLayoutConstraint.build(item: scrollContentView,
//                                                  attribute: .width,
//                                                  relatedBy: .equal,
//                                                  toItem: nil,
//                                                  attribute: .notAnAttribute,
//                                                  constant: contentWidth)
//        constraint.isActive = true
//    }
//
//    func addIllustrationMark(xConstraintValue: CGFloat) {
//        let view = RecordingAddedIllustrationMarkView(frame: CGRect(x: 0, y: 0, width: 100, height: scrollContentView.bounds.height))
//        scrollContentView.insertSubview(view, at: 0)
//
//        view.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.build(item: view,
//                                 attribute: .top,
//                                 toItem: scrollContentView,
//                                 attribute: .top,
//                                 constant: 5).isActive = true
//        NSLayoutConstraint.build(item: scrollContentView,
//                                 attribute: .bottom,
//                                 toItem: view,
//                                 attribute: .bottom,
//                                 constant: 5).isActive = true
//
//        NSLayoutConstraint.build(item: view,
//                                 attribute: .centerX,
//                                 toItem: scrollContentView,
//                                 attribute: .centerX,
//                                 constant: xConstraintValue - 50).isActive = true
//    }
//
//    @IBAction func addIllustration(_ sender: Any) {
//        addIllustrationMark(xConstraintValue: waveformPlot.waveformView.contentOffset.x)
//    }
//}

// MARK: - Buttons - start/pause/resume

extension AddIllustrationsViewController {
    @IBAction func startRecording(_ sender: UIButton) {
        startOrPause()
    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        recorder.stop()
        do {
            try recorder.finish()
        } catch RecorderError.directoryContentListingFailed(let error) {
            Log.error(error)
        } catch RecorderError.fileExportFailed {
            Log.error("Export failed")
        } catch {
            Log.error("Unknown error")
        }
    }

    @IBAction func clearButtonTapped(_ sender: UIButton) {
        self.clearRecordings()
    }

    @IBAction func playOrPauseButtonTapped(_ sender: UIButton) {
        self.playOrPause()
    }
}

// MARK: - Audio player

extension AddIllustrationsViewController {
    func playOrPause() {
        if player.state == .paused {
            guard let URL = self.url else {
                return
            }
            do {
                try player.playFile(with: URL, at: self.waveformWithIllustrationsPlot.waveformPlot.waveformView.currentTimeInterval)
            } catch AudioPlayerError.openFileFailed(let error) {
                Log.error(error)
            } catch {
                Log.error("Unknown error")
            }
        } else if player.state == .isPlaying {
            player.pause()
        }
    }
}

// MARK: - Audio recorder

extension AddIllustrationsViewController {
    func startOrPause() {
        if (recorder.isRecording) {
            recorder.pause()
        } else {
            do {
                try recorder.activateSession() { [weak self] permissionGranted in
                    DispatchQueue.main.async {
                        if permissionGranted {
                            self?.startRecording()
                        } else {
                            Log.error("Microphone access not granted.")
                        }
                    }
                }
            } catch RecorderError.sessionCategoryInvalid(let error) {
                Log.error(error)
            } catch RecorderError.sessionActivationFailed(let error) {
                Log.error(error)
            } catch {
                Log.error("Unknown error.")
            }
        }
    }
    
    func startRecording() {
        print("startRecording")
        do {
            if recorder.currentTime > 0.0 {
                let time = CMTime(seconds: self.waveformWithIllustrationsPlot.waveformPlot.waveformView.currentTimeInterval, preferredTimescale: 100)
                let range = CMTimeRange(start: time, duration: kCMTimeZero)
                
                try recorder.resume(from: range)
            } else {
                waveformWithIllustrationsPlot.waveformPlot.waveformView.values = []
                waveformWithIllustrationsPlot.waveformPlot.waveformView.reload()
                try recorder.start()
            }
        } catch RecorderError.directoryDeletionFailed(let error) {
            Log.error(error)
        } catch RecorderError.directoryCreationFailed(let error) {
            Log.error(error)
        } catch {
            Log.error("Unknown error.")
        }
    }
    
    private func clearRecordings() {
        do {
            try recorder.clearRecordings()
        } catch {
            let alertController = UIAlertController(title: "Błąd",
                                                    message: "Nie można usunąć nagrań",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true)
        }
    }

    private func retrieveFileDataAndSet(with url: URL) {
        do {
            loader = try FileDataLoader(fileURL: url)
            self.url = url
            let time = AudioUtils.time(from: (loader.fileDuration)!)
            let totalTimeString = String(format: "%02d:%02d:%02d",
                                         time.minutes,
                                         time.seconds,
                                         time.milliSeconds)
            totalTimeLabel.text = totalTimeString
            try loader.loadFile(completion: { [weak self] (array) in
                let model = self?.buildWaveformModel(from: array, numberOfSeconds: (self?.loader.fileDuration)!)
                DispatchQueue.main.async {
                    self?.waveformWithIllustrationsPlot.waveformPlot.waveformView.load(values: model ?? [])
                }
            })
        } catch FileDataLoaderError.openUrlFailed {
            let alertController = UIAlertController(title: "Błąd",
                                                    message: "Błędny url",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true)
        } catch {
            let alertController = UIAlertController(title: "Błąd",
                                                    message: "Nieznany",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true)
        }

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AudioFilesListViewController {
            viewController.directoryUrl = recorder.resultsDirectoryURL
            viewController.didSelectFileBlock = { [weak self] url in
                self?.retrieveFileDataAndSet(with: url)
                self?.navigationController?
                    .popViewController(animated: true)
            }
        }
    }
}

extension AddIllustrationsViewController {
    func createModel(value: CGFloat, with timeStamp: TimeInterval) -> WaveformModel {
        return WaveformModel(value: value, mode: .normal, timeStamp: timeStamp)
    }

    func buildWaveformModel(from samples: [Float], numberOfSeconds: Double) -> [[WaveformModel]] {
        // Liczba próbek na sekundę
        let sampleRate = WaveformConfiguration.microphoneSamplePerSecond

        let waveformSamples = samples.enumerated()
            .map { sample in
                WaveformModel(value: CGFloat(sample.element), mode: .normal, timeStamp: TimeInterval(sample.offset / sampleRate))
        }

        let samplesPerCell = sampleRate
        var result = [[WaveformModel]]()
        
        for cellIndex in 0..<Int(ceil(numberOfSeconds)) {
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

extension AddIllustrationsViewController: AudioControllerDelegate {
    func processSampleData(_ data: Float) {
        self.waveformWithIllustrationsPlot.waveformPlot.waveformView.setValue(data * AudioUtils.defaultWaveformFloatModifier,
                                                for: recorder.currentTime,
                                                mode: recorder.mode)
    }
}

// MARK: - WaveformViewDelegate

extension AddIllustrationsViewController: WaveformWithIllustrationsPlotDelegate {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval) {
        timeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }
}

extension AddIllustrationsViewController: RecorderDelegate {
    func recorderStateDidChange(with state: RecorderState) {
        switch state {
        case .isRecording:
            AudioController.sharedInstance.start()
            recordButton.setTitle("Pause", for: .normal)
            CATransaction.begin()
            waveformWithIllustrationsPlot.waveformPlot.waveformView.refresh()
            CATransaction.commit()
            waveformWithIllustrationsPlot.waveformPlot.waveformView.isUserInteractionEnabled = false
            self.totalTimeLabel.text = "00:00:00"
        case .stopped:
            AudioController.sharedInstance.stop()
            recordButton.setTitle("Start", for: .normal)

            waveformWithIllustrationsPlot.waveformPlot.waveformView.isUserInteractionEnabled = true
            waveformWithIllustrationsPlot.waveformPlot.waveformView.onPause()
            
            //setupScrollView(contentWidth: waveformPlot.waveformView.contentWidth)
        case .paused:
            AudioController.sharedInstance.stop()
            recordButton.setTitle("Resume", for: .normal)
            waveformWithIllustrationsPlot.waveformPlot.waveformView.isUserInteractionEnabled = true
            waveformWithIllustrationsPlot.waveformPlot.waveformView.onPause()
        case .notInitialized, .initialized:
            break
        }
    }
}

extension AddIllustrationsViewController: AudioPlayerDelegate {
    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
            case .isPlaying:
                waveformWithIllustrationsPlot.waveformPlot.waveformView.isUserInteractionEnabled = false
                waveformWithIllustrationsPlot.waveformPlot.waveformView.scrollToTheEnd()
                playOrPauseButton.setTitle("Pause", for: .normal)
            case .paused:
                waveformWithIllustrationsPlot.waveformPlot.waveformView.isUserInteractionEnabled = true
                waveformWithIllustrationsPlot.waveformPlot.waveformView.stopScrolling()
                playOrPauseButton.setTitle("Play", for: .normal)
        }
    }
}
