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
    private var audioModulesManager: AudioModulesManagerProtocol!
    private var timeInterval: TimeInterval = 0.0
    private lazy var timeFormatter: DateFormatter = {
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
        setupView()
        setupAudioModules()
        setupWaveformPlotDataManager()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AudioFilesListViewController {
            viewController.directoryUrl = audioModulesManager.resultsDirectoryURL
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
    private func setupAudioModules() {
        do {
            audioModulesManager = try AudioModulesManager()
            audioModulesManager.delegate = self
        } catch {
            showAlert(with: "Błąd", and: "Nagrywanie jest wyłączone", and: "Ok")
        }
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

    private func formattedDateString(with timeInterval: TimeInterval, and formatter: DateFormatter) -> String {
        let roundedValue = Double(round(100 * timeInterval) / 100)
        return formatter.string(from: Date(timeIntervalSince1970: roundedValue))
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
            try audioModulesManager.recordOrPause(at: timeInterval)
        } catch let error {
            Log.error(error)
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
            try audioModulesManager.playOrPause(at: timeInterval)
        } catch {
            Log.error("Error while exporting temporary file")
        }
    }

    private func clearRecordings() {
        do {
            try audioModulesManager.clearRecordings()
        } catch {
            showAlert(with: "Błąd", and: "Nie można usunąć nagrań", and: "OK")
        }
    }
}

// MARK: - Recorder state renderer

extension ViewController: AudioModulesManagerDelegate {
    func recorderStateDidChange(with state: AudioRecorderState) {
        switch state {
            case .isRecording:

                self.resetCurrentSampleData()
                self.plotDataManager.reset()

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
                waveformPlot.isUserInteractionEnabled = true
        }
    }

    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
            case .isPlaying:
                waveformPlot.isUserInteractionEnabled = false
                playOrPauseButton.setTitle("Pause", for: .normal)
                disableZoomAction()
                let stepWidth = CGFloat(plotDataManager.layersPerTimeInterval) / CGFloat((100 * plotDataManager.zoomLevel.samplesPerLayer))
                movementCoordinator.startScrolling(stepWidth: stepWidth)
            case .paused:
                waveformPlot.isUserInteractionEnabled = true
                playOrPauseButton.setTitle("Play", for: .normal)
                enableZoomAction()
                movementCoordinator.stopScrolling()
        }
    }

    func loaderStateDidChange(with state: FileDataLoaderState) {
        switch state {
            case .loading:
                break
            case .loaded(let values, let duration):
                let samplesPerPoint = CGFloat(values.count) / waveformPlot.bounds.width
                plotDataManager.loadData(from: values)
                plotDataManager.loadZoom(from: samplesPerPoint)
                waveformPlot.currentPosition = 0.0
                waveformPlot.reloadData()
                totalTimeLabel.text = self.timeFormatter.string(from: Date(timeIntervalSince1970: duration))
        }
    }
}

// MARK: - Before refactor

// MARK: - WaveformPlotDataManagerDelegate

extension ViewController: WaveformPlotDataManagerDelegate {
    private func resetCurrentSampleData() {
        timeInterval = 0.0
        plotDataManager.currentSampleIndex = 0
    }

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
    }

    func waveformPlot(_ waveformPlot: WaveformPlot, currentPositionDidChange position: CGFloat) {
        let validPosition = max(position, 0.0)
        timeInterval = plotDataManager.calculateTimeInterval(for: validPosition,
                                                             duration: audioModulesManager.recordingDuration)
        plotDataManager.currentSampleIndex = min(Int(validPosition / plotDataManager.sampleWidth), plotDataManager.numberOfSamples)
        timeLabel.text = formattedDateString(with: timeInterval, and: timeFormatter)

//        print("validPosition = \(validPosition)")
//        print("timeInterval = \(self.timeInterval)")
//        print("sampleIndex = \(self.sampleIndex)")
//        print("numberOfSamples = \(self.manager.numberOfSamples)")
    }
}

extension ViewController {
    func processSampleData(_ data: Float) {
        let data = WaveformModel(value: CGFloat(data * AudioUtils.defaultWaveformFloatModifier),
                                 mode: audioModulesManager.recordingMode,
                                 timeStamp: audioModulesManager.currentRecordingTime)
        waveformPlot.currentPosition = plotDataManager.newSampleOffset
        plotDataManager.setData(data: data)
        waveformPlot.reloadData()
        totalTimeLabel.text = formattedDateString(with: audioModulesManager.recordingDuration,
                                                  and: timeFormatter)
    }
}


