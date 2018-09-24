import UIKit
import AVFoundation

class AddIllustrationsViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var waveformWithIllustrationsPlot: WaveformWithIllustrationsPlot!
    @IBOutlet weak var playOrPauseButton: UIButton!
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
        setupWaveform()
        setupPlayer()
    }

    private func setupView() {
        totalTimeLabel.text = "00:00:00"
        timeLabel.text = "00:00:00"
        zoomValueLabel.text = "Zoom: \(waveformWithIllustrationsPlot.waveformPlot.currentZoomPercent())"
        disableZoomAction()
    }
    private func setupWaveform() {
        waveformWithIllustrationsPlot.delegate = self
    }

    private func setupPlayer() {
        self.player.delegate = self
    }

    @IBAction func addIllustration(_ sender: Any) {
        waveformWithIllustrationsPlot.addIllustrationMark()
    }
    
    @IBAction func zoomInButtonTapped(_ sender: UIButton) {
        self.waveformWithIllustrationsPlot.waveformPlot.zoomIn()
        self.zoomValueLabel.text = "Zoom: \(self.waveformWithIllustrationsPlot.waveformPlot.currentZoomPercent())"
    }
    
    @IBAction func zoomOutButtonTapped(_ sender: UIButton) {
        self.waveformWithIllustrationsPlot.waveformPlot.zoomOut()
        self.zoomValueLabel.text = "Zoom: \(self.waveformWithIllustrationsPlot.waveformPlot.currentZoomPercent())"
    }
}

// MARK: - Buttons - start/pause/resume

extension AddIllustrationsViewController {
    @IBAction func playOrPauseButtonTapped(_ sender: UIButton) {
        self.playOrPause()
    }
}

// MARK: - WaveformViewDelegate

extension AddIllustrationsViewController: WaveformWithIllustrationsPlotDelegate {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval) {
        timeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }
}

// MARK: - Audio player

extension AddIllustrationsViewController {
    func playOrPause() {
        if player.state == .paused {
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
                        if let timeInterval = self?.waveformWithIllustrationsPlot.waveformPlot.waveformView.currentTimeInterval {
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

extension AddIllustrationsViewController {
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
                let samplesPerPoint = CGFloat(values.count) / caller.waveformWithIllustrationsPlot.bounds.width
                DispatchQueue.main.async {
                    caller.waveformWithIllustrationsPlot.waveformPlot.waveformView.load(values: values)
                    caller.changeZoomSamplesPerPointForNewFile(samplesPerPoint)
                    caller.waveformWithIllustrationsPlot.setupContentViewOfScrollView()
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
        waveformWithIllustrationsPlot.waveformPlot.changeSamplesPerPoint(samplesPerPoint)
        waveformWithIllustrationsPlot.waveformPlot.resetZoom()
        zoomValueLabel.text = "Zoom: \(waveformWithIllustrationsPlot.waveformPlot.currentZoomPercent())"
        enableZoomAction()
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

// MARK: - Zoom

extension AddIllustrationsViewController {
    private func enableZoomAction() {
        zoomWrapperView.isUserInteractionEnabled = true
        zoomWrapperView.alpha = 1.0
    }
    
    private func disableZoomAction() {
        zoomWrapperView.isUserInteractionEnabled = false
        zoomWrapperView.alpha = 0.3
    }
}

extension AddIllustrationsViewController {
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

extension AddIllustrationsViewController: AudioPlayerDelegate {
    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
            case .isPlaying:
                waveformWithIllustrationsPlot.isUserInteractionEnabled = false
                waveformWithIllustrationsPlot.waveformPlot.waveformView.scrollToTheEndOfFile()
                playOrPauseButton.setTitle("Pause", for: .normal)
                disableZoomAction()
            case .paused:
                waveformWithIllustrationsPlot.isUserInteractionEnabled = true
                waveformWithIllustrationsPlot.waveformPlot.waveformView.stopScrolling()
                playOrPauseButton.setTitle("Play", for: .normal)
                enableZoomAction()
        }
    }
}
