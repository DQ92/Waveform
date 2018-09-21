import UIKit
import AVFoundation

class AddIllustrationsViewController: UIViewController {
    
    // MARK: - IBOutlets
    
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
            waveformWithIllustrationsPlot.waveformPlot.waveformView.values = values
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
        setupWaveform()
        setupPlayer()
    }

    private func setupView() {
        totalTimeLabel.text = "00:00:00"
        timeLabel.text = "00:00:00"
    }
    private func setupWaveform() {
        self.waveformWithIllustrationsPlot.waveformPlot.delegate = self
    }

    private func setupPlayer() {
        self.player.delegate = self
    }

    @IBAction func addIllustration(_ sender: Any) {
        waveformWithIllustrationsPlot.addIllustrationMark()
    }
}

// MARK: - Buttons - start/pause/resume

extension AddIllustrationsViewController {
    @IBAction func playOrPauseButtonTapped(_ sender: UIButton) {
        self.playOrPause()
    }
}

// MARK: - WaveformViewDelegate

extension AddIllustrationsViewController: WaveformPlotDelegate {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval) {
        timeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }
    
    func contentOffsetDidChange(_ contentOffset: CGPoint) {
        
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
                    self?.waveformWithIllustrationsPlot.setupContentViewOfScrollView()
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

extension AddIllustrationsViewController: AudioPlayerDelegate {
    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
            case .isPlaying:
                waveformWithIllustrationsPlot.isUserInteractionEnabled = false
                waveformWithIllustrationsPlot.scrollToTheEnd()
                playOrPauseButton.setTitle("Pause", for: .normal)
            case .paused:
                waveformWithIllustrationsPlot.isUserInteractionEnabled = true
                waveformWithIllustrationsPlot.stopScrolling()
                playOrPauseButton.setTitle("Play", for: .normal)
        }
    }
}
