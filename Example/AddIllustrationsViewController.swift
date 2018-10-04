import UIKit
import AVFoundation

class AddIllustrationsViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var illustrationPlot: IllustrationPlot!
    @IBOutlet weak var playOrPauseButton: UIButton!
    @IBOutlet weak var zoomWrapperView: UIView!
    @IBOutlet weak var zoomValueLabel: UILabel!
    @IBOutlet weak var zoomInButton: UIButton!
    @IBOutlet weak var zoomOutButton: UIButton!
    
    // MARK: - Private properties
    
    private var player: AudioPlayerProtocol = AVFoundationAudioPlayer()
    private var loader: FileDataLoaderProtocol = AudioToolboxFileDataLoader()
    
    private var manager: IllustrationPlotDataManager = IllustrationPlotDataManager()
    private var timeInterval: TimeInterval = 0.0
    private var sampleIndex: Int = 0
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss:SS"
        return formatter
    }()
    
    private lazy var movementCoordinator: MovementCoordinator = {
        return MovementCoordinator(plot: self.illustrationPlot)
    }()
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.setupPlayer()
        self.setupManager()
        self.setupIllustrationPlot()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AudioFilesListViewController {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            viewController.directoryUrl = documentsURL.appendingPathComponent("results")
            viewController.didSelectFileBlock = { [weak self] url in
                self?.retrieveFileDataAndSet(with: url)
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Actions

    @IBAction func playOrPauseButtonTapped(_ sender: UIButton) {
//        playOrPause()
    }
    
    @IBAction func addIllustration(_ sender: Any) {
        let data = createIllustrationMarkData(with: nil, and: timeInterval)
        let isMarkExistsAtCurrentTime = manager.checkIfIllustrationMarkExistsAtCurrentTime(for: 0, and: timeInterval)
        
        if isMarkExistsAtCurrentTime {
            manager.updateIllustrationMarkDatasource(for: 0, with: data)
        } else {
            manager.appendIllustrationMarkData(for: 0, with: data)
            illustrationPlot.addIllustrationMark(with: data, for: CGFloat(manager.zoomLevel.samplesPerLayer))
        }
    }
    
    @IBAction func zoomInButtonTapped(_ sender: UIButton) {
        self.manager.zoomIn()
        self.illustrationPlot.reloadData()
    }
    
    @IBAction func zoomOutButtonTapped(_ sender: UIButton) {
        self.manager.zoomOut()
        self.illustrationPlot.reloadData()
    }
    
    // MARK: - Other
    
    private func createIllustrationMarkData(with imageURL: URL?, and currentTimeInterval: TimeInterval) -> IllustrationMarkModel {
        let centerXConstraintValue = calculateXConstraintForCurrentWaveformPosition()
        let data = IllustrationMarkModel(timeInterval: currentTimeInterval,
                                         centerXConstraintValue: centerXConstraintValue,
                                         imageURL: imageURL,
                                         isActive: true)
        return data
    }
    
    private func calculateXConstraintForCurrentWaveformPosition() -> CGFloat {
        var centerXConstraintValue = illustrationPlot.calculateXConstraintForCurrentWaveformPosition()
        centerXConstraintValue *= CGFloat(manager.zoomLevel.samplesPerLayer)
        return centerXConstraintValue
    }
    
    private func retrieveFileDataAndSet(with url: URL) {
        do {
            try loader.loadFile(with: url, completion: { [weak self] values in
                guard let caller = self else {
                    return
                }
                let samplesPerPoint = CGFloat(values.count) / caller.illustrationPlot.bounds.width
                
                caller.manager.loadData(from: values)
                caller.manager.loadZoom(from: samplesPerPoint)
                
                caller.illustrationPlot.contentOffset = CGPoint(x: -caller.illustrationPlot.contentInset.left, y: 0.0)
                caller.illustrationPlot.currentPosition = 0.0
                caller.illustrationPlot.reloadData()
                caller.enableZoomAction()
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

extension AddIllustrationsViewController {
    private func setupView() {
        self.disableZoomAction()
    }
    
    private func setupPlayer() {
        self.player.delegate = self
    }
    
    private func setupManager() {
        self.manager.delegate = self
    }
    
    private func setupIllustrationPlot() {
        let offset = self.view.bounds.width * 0.5
        let timeIndicatorView = TimeIndicatorView(frame: .zero)
        timeIndicatorView.indicatorColor = .blue
        
        self.illustrationPlot.contentInset = UIEdgeInsets(top: 0.0, left: offset, bottom: 0.0, right: offset)
        self.illustrationPlot.standardTimeIntervalWidth = self.manager.standardTimeIntervalWidth
        self.illustrationPlot.timeIndicatorView = timeIndicatorView
        self.illustrationPlot.dataSource = self
        self.illustrationPlot.delegate = self
    }
}

// MARK: - Zoom

extension AddIllustrationsViewController {
    private func enableZoomAction() {
        self.zoomWrapperView.isUserInteractionEnabled = true
        self.zoomWrapperView.alpha = 1.0
    }
    
    private func disableZoomAction() {
        self.zoomWrapperView.isUserInteractionEnabled = false
        self.zoomWrapperView.alpha = 0.3
    }
}

// MARK: - AudioPlayerDelegate

extension AddIllustrationsViewController: AudioPlayerDelegate {
    func playerStateDidChange(with state: AudioPlayerState) {
        switch state {
        case .isPlaying:
            illustrationPlot.isUserInteractionEnabled = false
            playOrPauseButton.setTitle("Pause", for: .normal)
            disableZoomAction()
            
            let numberOfSteps = self.manager.numberOfSamples - self.sampleIndex
            let stepWidth = CGFloat(self.manager.layersPerTimeInterval) / CGFloat((100 * self.manager.zoomLevel.samplesPerLayer))
            
            movementCoordinator.startScrolling(numberOfSteps: numberOfSteps, stepWidth: stepWidth)
            
        case .paused:
            illustrationPlot.isUserInteractionEnabled = true
            playOrPauseButton.setTitle("Play", for: .normal)
            movementCoordinator.stopScrolling()
            enableZoomAction()
        }
    }
}

// MARK: - WaveformPlotDataManagerDelegate

extension AddIllustrationsViewController: WaveformPlotDataManagerDelegate {
    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, numberOfSamplesDidChange count: Int) {
        
    }
    
    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, zoomLevelDidChange level: ZoomLevel) {
        self.zoomValueLabel.text = "Zoom: \(level.percent)"
        self.illustrationPlot.reloadData()
    }
}

// MARK: - WaveformPlotDataSource

extension AddIllustrationsViewController: IllustrationPlotDataSource {
    func timeInterval(in illustrationPlot: IllustrationPlot) -> TimeInterval {
        return TimeInterval(self.manager.zoomLevel.samplesPerLayer)
    }
    
    func samplesPerLayer(for illustrationPlot: IllustrationPlot) -> CGFloat {
        return CGFloat(manager.zoomLevel.samplesPerLayer)
    }
    
    func getCurrentChapterIllustrationMarks() -> [IllustrationMarkModel] {
        return manager.illustrationMarksDatasource[0] ?? []
    }
    
    func numberOfTimeInterval(in illustrationPlot: IllustrationPlot) -> Int {
        return self.manager.numberOfTimeInterval
    }
    
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, samplesAtTimeIntervalIndex index: Int) -> [Sample] {
        return self.manager.samples(timeIntervalIndex: index)
    }

    func illustrationPlot(_ illustrationPlot: IllustrationPlot, timeIntervalWidthAtIndex index: Int) -> CGFloat {
        return self.manager.timeIntervalWidth(index: index)
    }
}

// MARK: - WaveformPlotDelegate

extension AddIllustrationsViewController: IllustrationPlotDelegate {
    func removeIllustrationMark(for timeInterval: TimeInterval) {
        if let index = manager.illustrationMarksDatasource[0]?.firstIndex(where: { $0.timeInterval == timeInterval }) {
            manager.illustrationMarksDatasource[0]?.remove(at: index)
        }
    }
    
    func setAllIllustrationMarksOfCurrentChapterInactive(except illustrationMarkData: IllustrationMarkModel) {
        var currentIllustrationMarksData = manager.illustrationMarksDatasource[0] ?? []
        
        currentIllustrationMarksData = currentIllustrationMarksData.map {
            if $0 == illustrationMarkData {
                return IllustrationMarkModel(timeInterval: $0.timeInterval, centerXConstraintValue: $0.centerXConstraintValue, imageURL: $0.imageURL, isActive: true)
            } else {
                return IllustrationMarkModel(timeInterval: $0.timeInterval, centerXConstraintValue: $0.centerXConstraintValue, imageURL: $0.imageURL, isActive: false)
            }
        }
        
        manager.illustrationMarksDatasource[0] = currentIllustrationMarksData
    }
    
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, contentOffsetDidChange contentOffset: CGPoint) {
        print("contentOffset.x = \(contentOffset.x)")
    }
    
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, currentPositionDidChange position: CGFloat) {
        let validPosition = max(position, 0.0)
        
        self.timeInterval = self.manager.calculateTimeInterval(for: validPosition, duration: self.loader.fileDuration ?? 0)
        self.sampleIndex = min(Int(validPosition / self.manager.sampleWidth), self.manager.numberOfSamples)
        self.timeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: self.timeInterval))
        
//        print("validPosition = \(validPosition)")
//        print("timeInterval = \(self.timeInterval)")
//        print("sampleIndex = \(self.sampleIndex)")
//        print("numberOfSamples = \(self.manager.numberOfSamples)")
    }
}
