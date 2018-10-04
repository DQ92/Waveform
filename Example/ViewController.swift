import UIKit
import AVFoundation

class ViewController: UIViewController {

    // MARK: - IBOutlets

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

    // MARK: - Private properties

    private var plotDataManager: WaveformPlotDataManager = WaveformPlotDataManager()
    private let audioModulesManager: AudioModulesManagerProtocol = AudioModulesManager()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss:SS"
        return formatter
    }()

    private lazy var movementCoordinator: MovementCoordinator = {
        return MovementCoordinator(plot: self.waveformPlot)
    }()

    // MARK: - IBActions

    @IBAction func startRecording(_ sender: UIButton) {
        recordOrPause()
    }

    @IBAction func finishButtonTapped(_ sender: Any) {
        finishRecording()
    }

    @IBAction func clearButtonTapped(_ sender: UIButton) {
        clearRecordings()
    }

    @IBAction func playOrPauseButtonTapped(_ sender: UIButton) {
        playOrPause()
    }

    @IBAction func zoomInButtonTapped(_ sender: UIButton) {
        plotDataManager.zoomIn()
        waveformPlot.reloadData()
    }

    @IBAction func zoomOutButtonTapped(_ sender: UIButton) {
        plotDataManager.zoomOut()
        waveformPlot.reloadData()
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AudioFilesListViewController {
            viewController.directoryUrl = recorder.resultsDirectoryURL
            viewController.didSelectFileBlock = { [weak self] url in
                self?.loadFile(with: url)
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: - After refactor

// MARK: - Setup

extension ViewController {
    private func setup() {
        setupView()
        setupAudioModules()
        setupWaveformPlotDataManager()
    }

    private func setupAudioModules() {
        audioModulesManager.delegate = self
    }

    private func setupWaveformPlotDataManager() {
        self.plotDataManager.delegate = self
    }

    private func setupView() {
        setupWaveformPlot()
        disableZoomAction()
    }

    private func setupWaveformPlot() {
        let offset = view.bounds.width * 0.5
        let timeIndicatorView = TimeIndicatorView(frame: .zero)
        timeIndicatorView.indicatorColor = .blue

        waveformPlot.contentInset = UIEdgeInsets(top: 0.0, left: offset, bottom: 0.0, right: offset)
        waveformPlot.timeIndicatorView = timeIndicatorView
        waveformPlot.dataSource = self
        waveformPlot.delegate = self
    }

    private func enableZoomAction() {
        self.zoomWrapperView.isUserInteractionEnabled = true
        self.zoomWrapperView.alpha = 1.0
    }

    private func disableZoomAction() {
        self.zoomWrapperView.isUserInteractionEnabled = false
        self.zoomWrapperView.alpha = 0.3
    }
}

// MARK: - Audio modules manager

extension ViewController {
    private func loadFile(with url: URL) {
        do {
            try audioModulesManager.loadFile(with: url)
        } catch FileDataLoaderError.openUrlFailed {
            showAlert(with: "Błąd", and: "Błędny url", and: "Ok")
        } catch {
            showAlert(with: "Błąd", and: "Nieznany", and: "Ok")
        }
    }

    private func recordOrPause() {
        do {
            try audioModulesManager.recordOrPause()
        } catch let error {
            Log.error(error)
        } catch {
            Log.error("Unknown error.")
        }
    }

    private func finishRecording() {
        do {
            try audioModulesManager.finishRecording()
        } catch AudioRecorderError.directoryContentListingFailed(let error) {
            Log.error(error)
        } catch AudioRecorderError.fileExportFailed {
            Log.error("Export failed")
        } catch {
            Log.error("Unknown error")
        }
    }

    private func playOrPause() {
        do {
            try audioModulesManager.playOrPause()
        } catch {
            Log.error("Error while exporting temporary file")
        }
    }

    private func clearRecordings() {
        do {
            try audioModulesManager.clearRecordings()
        } catch {
            let alertController = UIAlertController(title: "Błąd",
                                                    message: "Nie można usunąć nagrań",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true)
        }
    }
}

// MARK: - Recorder state renderer

extension ViewController: AudioModulesManagerDelegate {
    func recorderStateDidChange(with state: AudioRecorderState) {
        switch state {
            case .isRecording:
                recordButton.setTitle("Pause", for: .normal)
                disableZoomAction()
                waveformPlot.isUserInteractionEnabled = true
            case .stopped:
                recordButton.setTitle("Start", for: .normal)
                enableZoomAction()
                waveformPlot.isUserInteractionEnabled = true
            case .paused:
                recordButton.setTitle("Resume", for: .normal)
                enableZoomAction()
                waveformPlot.isUserInteractionEnabled = true
            case .fileLoaded:
                recordButton.setTitle("Resume", for: .normal)
                enableZoomAction()
        }
    }

    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
            case .isPlaying:
                waveformPlot.isUserInteractionEnabled = false
                playOrPauseButton.setTitle("Pause", for: .normal)
                disableZoomAction()
            case .paused:
                waveformPlot.isUserInteractionEnabled = true
                playOrPauseButton.setTitle("Play", for: .normal)
                enableZoomAction()
        }
    }
}

// MARK: - Before refactor

// MARK: - WaveformPlotDataManagerDelegate

extension ViewController: WaveformPlotDataManagerDelegate {
    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, numberOfSamplesDidChange count: Int) {
    }

    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, zoomLevelDidChange level: ZoomLevel) {
        self.zoomValueLabel.text = "Zoom: \(level.percent)"
    }
}

// MARK: - WaveformPlotDataSource

extension ViewController: WaveformPlotDataSource {
    func numberOfTimeInterval(in waveformPlot: WaveformPlot) -> Int {
        return self.plotDataManager.numberOfTimeInterval
    }

    func waveformPlot(_ waveformPlot: WaveformPlot, samplesAtTimeIntervalIndex index: Int) -> [Sample] {
        return self.plotDataManager.samples(timeIntervalIndex: index)
    }

    func waveformPlot(_ waveformPlot: WaveformPlot, timeIntervalWidthAtIndex index: Int) -> CGFloat {
        return self.plotDataManager.timeIntervalWidth(index: index)
    }
}

// MARK: - WaveformPlotDelegate

extension ViewController: WaveformPlotDelegate {
    func waveformPlot(_ waveformPlot: WaveformPlot, contentOffsetDidChange contentOffset: CGPoint) {
//        print("contentOffset.x = \(contentOffset.x)")
    }

    func waveformPlot(_ waveformPlot: WaveformPlot, currentPositionDidChange position: CGFloat) {
        let validPosition = max(position, 0.0)
        self.timeInterval = self.plotDataManager.calculateTimeInterval(for: validPosition, duration: self.recorder.duration)
        self.sampleIndex = min(Int(validPosition / self.plotDataManager.sampleWidth), self.plotDataManager.numberOfSamples)
        let roundedValue = Double(round(100 * timeInterval) / 100)
        self.timeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: roundedValue))
//
//        print("validPosition = \(validPosition)")
//        print("timeInterval = \(self.timeInterval)")
//        print("sampleIndex = \(self.sampleIndex)")
//        print("numberOfSamples = \(self.manager.numberOfSamples)")
    }
}

// MARK: - MicrophoneControllerDelegate

extension ViewController: MicrophoneControllerDelegate {
    func processSampleData(_ data: Float) {
        let data = WaveformModel(value: CGFloat(data * AudioUtils.defaultWaveformFloatModifier),
                                 mode: recorder.mode,
                                 timeStamp: recorder.currentTime)
        let offset = CGFloat(self.sampleIndex + 1) * self.plotDataManager.sampleWidth
        self.plotDataManager.setData(data: data, atIndex: self.sampleIndex)
        self.waveformPlot.currentPosition = offset
        self.waveformPlot.reloadData()
        let roundedValue = Double(round(100 * self.recorder.duration) / 100)
        self.totalTimeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: roundedValue))
    }
}


