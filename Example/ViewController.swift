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
    @IBOutlet weak var zoomWrapperView: UIView!
    @IBOutlet weak var zoomValueLabel: UILabel!
    @IBOutlet weak var zoomInButton: UIButton!
    @IBOutlet weak var zoomOutButton: UIButton!

    // MARK: - Private Properties

    private var recorder: RecorderProtocol = AVFoundationRecorder()
    private var player: AudioPlayerProtocol = AVFoundationAudioPlayer()
    private var loader: FileDataLoader!
    private var url: URL!

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
        setupMicrophoneController()
    }

    private func setupView() {
        totalTimeLabel.text = "00:00:00"
        timeLabel.text = "00:00:00"
        zoomValueLabel.text = "Zoom: \(waveformPlot.currentZoomPercent())"
        disableZoomAction()
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

    private func setupMicrophoneController() {
        AudioToolboxMicrophoneController.shared.delegate = self
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

    @IBAction func zoomInButtonTapped(_ sender: UIButton) {
        self.waveformPlot.zoomIn()
        self.zoomValueLabel.text = "Zoom: \(self.waveformPlot.currentZoomPercent())"
    }

    @IBAction func zoomOutButtonTapped(_ sender: UIButton) {
        self.waveformPlot.zoomOut()
        self.zoomValueLabel.text = "Zoom: \(self.waveformPlot.currentZoomPercent())"
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
                waveformPlot.reset()
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
                guard let caller = self else {
                    return
                }
                let values = caller.buildWaveformModel(from: array, numberOfSeconds: (self?.loader.fileDuration)!)
                let samplesPerPoint = CGFloat(values.count) / caller.waveformPlot.bounds.width
                DispatchQueue.main.async {
                    caller.waveformPlot.waveformView.load(values: values)
                    caller.changeZoomSamplesPerPointForNewFile(samplesPerPoint)
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

    private func changeZoomSamplesPerPointForNewFile(_ samplesPerPoint: CGFloat) {
        waveformPlot.changeSamplesPerPoint(samplesPerPoint)
        waveformPlot.resetZoom()
        zoomValueLabel.text = "Zoom: \(waveformPlot.currentZoomPercent())"
        enableZoomAction()
    }
}

extension ViewController {
    func createModel(value: CGFloat, with timeStamp: TimeInterval) -> WaveformModel {
        return WaveformModel(value: value, mode: .normal, timeStamp: timeStamp)
    }

    func buildWaveformModel(from samples: [Float], numberOfSeconds: Double) -> [WaveformModel] {
        let sampleRate = WaveformConfiguration.microphoneSamplePerSecond

        return samples.enumerated().map { sample in
            WaveformModel(value: CGFloat(sample.element), mode: .normal, timeStamp:
            TimeInterval(sample.offset / sampleRate))
        }
    }
}

extension ViewController: MicrophoneControllerDelegate {
    func processSampleData(_ data: Float) {
        self.waveformPlot.waveformView.setCurrentValue(data * AudioUtils.defaultWaveformFloatModifier,
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

// MARK: - Zoom

extension ViewController {
    private func enableZoomAction() {
        zoomWrapperView.isUserInteractionEnabled = true
        zoomWrapperView.alpha = 1.0
    }

    private func disableZoomAction() {
        zoomWrapperView.isUserInteractionEnabled = false
        zoomWrapperView.alpha = 0.3
    }
}

extension ViewController: RecorderDelegate {
    func recorderStateDidChange(with state: RecorderState) {
        switch state {
            case .isRecording:
                AudioToolboxMicrophoneController.shared.start()
                recordButton.setTitle("Pause", for: .normal)
                waveformPlot.recordingModeEnabled = true
                totalTimeLabel.text = "00:00:00"
                disableZoomAction()

            case .stopped:
                AudioToolboxMicrophoneController.shared.stop()
                recordButton.setTitle("Start", for: .normal)
                waveformPlot.recordingModeEnabled = false
                enableZoomAction()
                
//                let samplesPerPoint = CGFloat(self.waveformPlot.waveformView.values.count) / self.waveformPlot.waveformView.bounds.width
//                self.waveformPlot.zoom = Zoom(samplesPerPoint: samplesPerPoint)

            case .paused, .fileLoaded:
                AudioToolboxMicrophoneController.shared.stop()
                recordButton.setTitle("Resume", for: .normal)
                waveformPlot.recordingModeEnabled = false
                enableZoomAction()
        }
    }
}

extension ViewController: AudioPlayerDelegate {
    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
            case .isPlaying:
                waveformPlot.waveformView.isUserInteractionEnabled = false
                waveformPlot.waveformView.scrollToTheEndOfFile()
                playOrPauseButton.setTitle("Pause", for: .normal)
                disableZoomAction()
            case .paused:
                waveformPlot.waveformView.isUserInteractionEnabled = true
                waveformPlot.waveformView.stopScrolling()
                playOrPauseButton.setTitle("Play", for: .normal)
                enableZoomAction()
        }
    }
}
