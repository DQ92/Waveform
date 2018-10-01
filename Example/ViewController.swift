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
    
    private var recorder: RecorderProtocol = AVFoundationRecorder()
    private var player: AudioPlayerProtocol = AVFoundationAudioPlayer()
    private var loader: FileDataLoaderProtocol = AudioToolboxFileDataLoader()
    
    private var manager: WaveformPlotDataManager = WaveformPlotDataManager()
    private var timeInterval: TimeInterval = 0.0
    private var sampleIndex: Int = 0
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss:SS"
        return formatter
    }()
    
    private lazy var movementCoordinator: MovementCoordinator = {
        return MovementCoordinator(plot: self.waveformPlot)
    }()
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
        self.setupRecorder()
        self.setupPlayer()
        self.setupManager()
        self.setupWaveformPlot()
        self.setupMicrophoneController()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AudioFilesListViewController {
            if recorder.recorderState == .isRecording {
                recorder.pause()
            }
            viewController.directoryUrl = recorder.resultsDirectoryURL
            viewController.didSelectFileBlock = { [weak self] url in
                self?.retrieveFileDataAndSet(with: url)
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Actions
    
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
        self.manager.zoomIn()
        self.waveformPlot.reloadData()
    }
    
    @IBAction func zoomOutButtonTapped(_ sender: UIButton) {
        self.manager.zoomOut()
        self.waveformPlot.reloadData()
    }
    
    // MARK: - Other
    
    private func retrieveFileDataAndSet(with url: URL) {
        do {
            if recorder.recorderState == .isRecording {
                recorder.stop()
            }
            try recorder.openFile(with: url)
            try loader.loadFile(with: url, completion: { [weak self] values in
                guard let caller = self else {
                    return
                }
                let samplesPerPoint = CGFloat(values.count) / caller.waveformPlot.bounds.width
                
                caller.manager.loadData(from: values)
                caller.manager.loadZoom(from: samplesPerPoint)
                
                caller.waveformPlot.contentOffset = CGPoint(x: caller.waveformPlot.contentInset.left, y: 0.0)
                caller.waveformPlot.currentPosition = 0.0
                caller.waveformPlot.reloadData()
            })
            totalTimeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: loader.fileDuration))
            
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
    
    private func resetCurrentSampleData() {
        self.timeInterval = 0.0
        self.sampleIndex = 0
    }
}

// MARK: - Setup

extension ViewController {
    private func setupView() {
        self.disableZoomAction()
    }
    
    private func setupRecorder() {
        self.recorder.delegate = self
    }
    
    private func setupPlayer() {
        self.player.delegate = self
    }
    
    private func setupManager() {
        self.manager.delegate = self
    }
    
    private func setupWaveformPlot() {
        let offset = self.waveformPlot.bounds.width * 0.5
        let timeIndicatorView = TimeIndicatorView(frame: .zero)
        timeIndicatorView.indicatorColor = .blue
        
        self.waveformPlot.contentInset = UIEdgeInsets(top: 0.0, left: offset, bottom: 0.0, right: offset)
        self.waveformPlot.timeIndicatorView = timeIndicatorView
        self.waveformPlot.contentOffset = CGPoint(x: -offset, y: 0.0)
        self.waveformPlot.standardTimeIntervalWidth = self.manager.standardTimeIntervalWidth
        self.waveformPlot.dataSource = self
        self.waveformPlot.delegate = self
    }
    
    private func setupMicrophoneController() {
        AudioToolboxMicrophoneController.shared.delegate = self
    }
}

// MARK: - Zoom

extension ViewController {
    private func enableZoomAction() {
        self.zoomWrapperView.isUserInteractionEnabled = true
        self.zoomWrapperView.alpha = 1.0
    }
    
    private func disableZoomAction() {
        self.zoomWrapperView.isUserInteractionEnabled = false
        self.zoomWrapperView.alpha = 0.3
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
                self.resetCurrentSampleData()
                self.manager.reset()
                try recorder.start()
            } else {
                let time = CMTime(seconds: self.timeInterval, preferredTimescale: 100)
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

    private func finishRecording() {
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
                        let timeInterval = self?.timeInterval ?? 0.0
                        try self?.player.playFile(with: URL, at: timeInterval)
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

// MARK: - RecorderDelegate

extension ViewController: RecorderDelegate {
    func recorderStateDidChange(with state: RecorderState) {
        switch state {
        case .isRecording:
            AudioToolboxMicrophoneController.shared.start()
            self.recordButton.setTitle("Pause", for: .normal)
            self.totalTimeLabel.text = "00:00:00"
            disableZoomAction()
        case .stopped:
            AudioToolboxMicrophoneController.shared.stop()
            self.recordButton.setTitle("Start", for: .normal)
            enableZoomAction()
            
//            let samplesPerPoint = CGFloat(self.manager.numberOfSamples) / self.waveformPlot.bounds.width
//            self.manager.loadZoom(from: samplesPerPoint)
//            self.waveformPlot.reloadData()
            
        case .paused:
            AudioToolboxMicrophoneController.shared.stop()
            self.recordButton.setTitle("Resume", for: .normal)
            enableZoomAction()
        case .fileLoaded:
            AudioToolboxMicrophoneController.shared.stop()
            self.recordButton.setTitle("Resume", for: .normal)
            enableZoomAction()
        }
    }
}

// MARK: - AudioPlayerDelegate

extension ViewController: AudioPlayerDelegate {
    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
        case .isPlaying:
            waveformPlot.isUserInteractionEnabled = false
            playOrPauseButton.setTitle("Pause", for: .normal)
            disableZoomAction()
            
            let numberOfSteps = self.manager.numberOfSamples - self.sampleIndex
            let stepWidth = CGFloat(self.manager.layersPerTimeInterval) / CGFloat((100 * self.manager.zoomLevel.samplesPerLayer))

            movementCoordinator.startScrolling(numberOfSteps: numberOfSteps, stepWidth: stepWidth)
            
        case .paused:
            waveformPlot.isUserInteractionEnabled = true
            playOrPauseButton.setTitle("Play", for: .normal)
            movementCoordinator.stopScrolling()
            enableZoomAction()
        }
    }
}

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
        return self.manager.numberOfTimeInterval
    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, samplesAtTimeIntervalIndex index: Int) -> [Sample] {
        return self.manager.samples(timeIntervalIndex: index)
    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, timeIntervalWidthAtIndex index: Int) -> CGFloat {
        return self.manager.timeIntervalWidth(index: index)
    }
}

// MARK: - WaveformPlotDelegate

extension ViewController: WaveformPlotDelegate {
    func waveformPlot(_ waveformPlot: WaveformPlot, contentOffsetDidChange contentOffset: CGPoint) {
        print("contentOffset.x = \(contentOffset.x)")
    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, currentPositionDidChange position: CGFloat) {
        let validPosition = max(position, 0.0)
        
        self.timeInterval = self.manager.calculateTimeInterval(for: validPosition)
        self.sampleIndex = min(Int(validPosition / self.manager.sampleWidth), self.manager.numberOfSamples)
        self.timeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: self.timeInterval))
        
        print("validPosition = \(validPosition)")
        print("timeInterval = \(self.timeInterval)")
        print("sampleIndex = \(self.sampleIndex)")
        print("numberOfSamples = \(self.manager.numberOfSamples)")
    }
}

// MARK: - MicrophoneControllerDelegate

extension ViewController: MicrophoneControllerDelegate {
    func processSampleData(_ data: Float) {
        let data = WaveformModel(value: CGFloat(data * AudioUtils.defaultWaveformFloatModifier),
                                 mode: recorder.mode,
                                 timeStamp: recorder.currentTime)
        
        let offset = CGFloat(self.sampleIndex + 1) * self.manager.sampleWidth
        
        self.manager.setData(data: data, atIndex: self.sampleIndex)
        self.waveformPlot.currentPosition = offset
        self.waveformPlot.reloadData()
    }
}
