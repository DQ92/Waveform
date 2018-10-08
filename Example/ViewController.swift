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

    var audioWaveformFacade: AudioWaveformFacadeProtocol!

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss:SS"
        return formatter
    }()

    private lazy var movementCoordinator: AutoScrollCoordinator = {
        return AutoScrollCoordinator(plot: self.waveformPlot)
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
        audioWaveformFacade.zoomIn()
        waveformPlot.reloadData()
    }

    @IBAction func zoomOutButtonTapped(_ sender: UIButton) {
        audioWaveformFacade.zoomOut()
        waveformPlot.reloadData()
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioFacade()
        setupView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AudioFilesListViewController {
            viewController.directoryUrl = audioWaveformFacade.resultsDirectoryURL
            viewController.didSelectFileBlock = { [weak self] url in
                self?.loadFile(with: url)
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: - Setup

extension ViewController {
    private func setupAudioFacade() {
        do {
            let audioModulesManager = try AudioModulesManager()
            let plotDataManger = WaveformPlotDataManager()
            audioWaveformFacade = AudioWaveformFacade(plotDataManager: plotDataManger, audioModulesManager: audioModulesManager)
            audioWaveformFacade.delegate = self

            waveformPlot.dataSource = audioWaveformFacade
            waveformPlot.delegate = audioWaveformFacade
        } catch {
            showAlert(with: "Błąd", and: "Nagrywanie jest wyłączone", and: "Ok")
        }
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
            try audioWaveformFacade.loadFile(with: url)
        } catch FileDataLoaderError.openUrlFailed {
            showAlert(with: "Błąd", and: "Błędny url", and: "Ok")
        } catch {
            showAlert(with: "Błąd", and: "Nieznany", and: "Ok")
        }
    }

    private func recordOrPause() {
        do {
            try audioWaveformFacade.recordOrPause(at: audioWaveformFacade.timeInterval)
        } catch let error {
            Log.error(error)
        }
    }

    private func finishRecording() {
        do {
            try audioWaveformFacade.finishRecording()
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
            try audioWaveformFacade.playOrPause(at: audioWaveformFacade.timeInterval)
        } catch {
            Log.error("Error while exporting temporary file")
        }
    }

    private func clearRecordings() {
        do {
            try audioWaveformFacade.clearRecordings()
        } catch {
            showAlert(with: "Błąd", and: "Nie można usunąć nagrań", and: "OK")
        }
    }
}

// MARK: - Recorder state renderer

extension ViewController {
    func recorderStateDidChange(with state: AudioRecorderState) {
        switch state {
            case .started, .resumed:
                recordButton.setTitle("Pause", for: .normal)
                disableZoomAction()
                waveformPlot.isUserInteractionEnabled = true
            case .stopped:
                recordButton.setTitle("Start", for: .normal)
                enableZoomAction()
                waveformPlot.isUserInteractionEnabled = true
            case .paused, .fileLoaded:
                recordButton.setTitle("Resume", for: .normal)
                enableZoomAction()
                waveformPlot.isUserInteractionEnabled = true
        }
    }

    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
            case .playing:
                waveformPlot.isUserInteractionEnabled = false
                playOrPauseButton.setTitle("Pause", for: .normal)
                disableZoomAction()
                movementCoordinator.startScrolling(stepWidth: audioWaveformFacade.autoscrollStepWidth)
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
                audioWaveformFacade.fileLoaded(with: values, and: samplesPerPoint)
                waveformPlot.currentPosition = 0.0
                waveformPlot.reloadData()
                totalTimeLabel.text = formattedDateString(with: duration, and: timeFormatter)
        }
    }
}

extension ViewController: AudioWaveformFacadeDelegate {
    func leadingLineTimeIntervalDidChange(to timeInterval: TimeInterval) {
        let formattedTimeInterval = formattedDateString(with: timeInterval, and: timeFormatter)
        timeLabel.text = formattedTimeInterval
    }

    func audioDurationDidChange(to timeInterval: TimeInterval) {
        let formattedTimeInterval = formattedDateString(with: timeInterval, and: timeFormatter)
        totalTimeLabel.text = formattedTimeInterval
    }

    func shiftOffset(to offset: CGFloat) {
        waveformPlot.currentPosition = offset
        waveformPlot.reloadData()
    }

    func zoomLevelDidChange(to level: ZoomLevel) {
        self.zoomValueLabel.text = "Zoom: \(level.percent)"
    }
    
    func currentPositionDidChange(_ position: CGFloat) {
        self.waveformPlot.currentPosition = position
    }
}
