import UIKit
import AVFoundation

class ViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet var recordingTimeLabel: UILabel!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var waveformPlot: WaveformPlot!
    @IBOutlet weak var playOrPauseButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!

    // MARK: - Private Properties

    private var recorder: RecorderProtocol = AVFoundationRecorder()
    private var player: AudioPlayerProtocol = AVFoundationAudioPlayer()
    private var loader: FileDataLoader!
    private var url: URL!
    private var values = [[WaveformModel]]() {
        didSet {
            self.waveformPlot.waveformView.values = values
        }
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
        self.waveformPlot.delegate = self
    }

    private func setupPlayer() {
        self.player.delegate = self
    }

    private func setupAudioController() {
        AudioController.sharedInstance.prepare(with: AudioUtils.defualtSampleRate)
        AudioController.sharedInstance.delegate = self
    }
}

// MARK: - Buttons - start/pause/resume

extension ViewController {
    @IBAction func startRecording(_ sender: UIButton) {
        recordOrPause()
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

extension ViewController {
    func playOrPause() {
        if player.state == .paused && recorder.recorderState != .isRecording {
            playFileInRecording()
        } else if player.state == .isPlaying {
            player.pause()
        }
    }

    private func playFileInRecording() {
        do {
            try recorder.temporallyExportRecordedFileAndGetUrl { [weak self] url in
                guard let URL = url else {
                    return
                }

                DispatchQueue.main.async {
                    do {
                        var time = 0.0
                        if let timeInterval = self?.waveformPlot.waveformView.currentTimeInterval {
                            time = timeInterval
                        }
                        try self?.player.playFile(with: URL, at: time)
                    } catch AudioPlayerError.openFileFailed(let error) {
                        Log.error(error)
                    } catch {
                        Log.error("Unknown error")
                    }
                }
            }
        } catch {
            Log.error("Error while exporting temporary file")
        }
    }
}

// MARK: - Audio recorder

extension ViewController {
    func recordOrPause() {
        if player.state == .isPlaying {
            player.pause()
        }

        if recorder.recorderState == .isRecording {
            recorder.pause()
            //        } else if (currentlyShownTime < recorder.currentTime) {
            //            startRecording(with: true)
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
        Log.info("Start recording")
        do {
            if recorder.recorderState == .stopped {
                waveformPlot.waveformView.values = []
                waveformPlot.waveformView.reload()
                try recorder.start()
            } else {
                let timeInterval = self.waveformPlot.waveformView.currentTimeInterval
                let time = CMTime(seconds: timeInterval, preferredTimescale: 100)
                let range = CMTimeRange(start: time, duration: kCMTimeZero)
                try recorder.resume(from: range)
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
}

// MARK: - Loader

extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AudioFilesListViewController {
            if recorder.recorderState == .isRecording {
                recorder.pause()
            }
            viewController.directoryUrl = recorder.resultsDirectoryURL
            viewController.didSelectFileBlock = { [weak self] url in
                self?.retrieveFileDataAndSet(with: url)
                self?.navigationController?
                     .popViewController(animated: true)
            }
        }
    }

    private func retrieveFileDataAndSet(with url: URL) {
        do {
            if recorder.recorderState == .isRecording {
                recorder.stop()
            }
            loader = try FileDataLoader(fileURL: url)
            let time = AudioUtils.time(from: (loader.fileDuration)!)
            let totalTimeString = String(format: "%02d:%02d:%02d",
                                         time.minutes,
                                         time.seconds,
                                         time.milliSeconds)
            totalTimeLabel.text = totalTimeString
            try recorder.openFile(with: url)
            try loader.loadFile(completion: { [weak self] (array) in
                let model = self?.buildWaveformModel(from: array, numberOfSeconds: (self?.loader.fileDuration)!)
                DispatchQueue.main.async {
                    self?.waveformPlot.waveformView.load(values: model ?? [])
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
}

extension ViewController {
    func createModel(value: CGFloat, with timeStamp: TimeInterval) -> WaveformModel {
        return WaveformModel(value: value, mode: .normal, timeStamp: timeStamp)
    }

    func buildWaveformModel(from samples: [Float], numberOfSeconds: Double) -> [[WaveformModel]] {
        let sampleRate = WaveformConfiguration.microphoneSamplePerSecond

        let waveformSamples = samples.enumerated()
                                     .map { sample in
                                         WaveformModel(value: CGFloat(sample.element), mode: .normal, timeStamp:
                                         TimeInterval(sample.offset / sampleRate))
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

extension ViewController: AudioControllerDelegate {
    func processSampleData(_ data: Float) {
        self.waveformPlot.waveformView.setValue(data * AudioUtils.defaultWaveformFloatModifier,
                                                for: recorder.currentTime,
                                                mode: recorder.mode)
    }
}

// MARK: - WaveformViewDelegate

extension ViewController: WaveformPlotDelegate {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval) {
        timeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }

    func contentOffsetDidChange(_ contentOffset: CGPoint) {

    }
}

extension ViewController: RecorderDelegate {
    func recorderStateDidChange(with state: RecorderState) {
        switch state {
            case .isRecording:
                AudioController.sharedInstance.start()
                recordButton.setTitle("Pause", for: .normal)
                CATransaction.begin()
                waveformPlot.waveformView.refresh()
                CATransaction.commit()
                waveformPlot.waveformView.isUserInteractionEnabled = false
                self.totalTimeLabel.text = "00:00:00"

            case .stopped:
                AudioController.sharedInstance.stop()
                recordButton.setTitle("Start", for: .normal)
                waveformPlot.waveformView.isUserInteractionEnabled = true
                waveformPlot.waveformView.onPause()

            case .paused, .fileLoaded:
                AudioController.sharedInstance.stop()
                recordButton.setTitle("Resume", for: .normal)
                waveformPlot.waveformView.isUserInteractionEnabled = true
                waveformPlot.waveformView.onPause()
        }
    }
}

extension ViewController: AudioPlayerDelegate {
    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
            case .isPlaying:
                waveformPlot.waveformView.isUserInteractionEnabled = false
                waveformPlot.waveformView.scrollToTheEnd()
                playOrPauseButton.setTitle("Pause", for: .normal)
            case .paused:
                waveformPlot.waveformView.isUserInteractionEnabled = true
                waveformPlot.waveformView.stopScrolling()
                playOrPauseButton.setTitle("Play", for: .normal)
        }
    }
}
