import UIKit

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var recordingTimeLabel: UILabel!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet weak var waveformCollectionView: WaveformView!
    @IBOutlet weak var collectionViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    // MARK: - Private properties
    
    private var currentIndex: Int?
    private let shouldClearFiles = false
    private var recorder: RecorderProtocol = AVFoundationRecorder()
    private var currentlySelectedTime: TimeInterval = 0.0
    private var loader: FileDataLoader!

    private var values = [[WaveformModel]]() {
        didSet {
            waveformCollectionView.values = values
        }
    }
    private var sampleIndex = 0 {
        didSet {
            waveformCollectionView.sampleIndex = sampleIndex
        }
    }
    private var sec: Int = 0
    private var elementsPerSecond: Int {
        return WaveformConfiguration.microphoneSamplePerSecond
    }

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupRecorder()
        setupWaveform()
        setupAudioController()
    }
    
    private func setupView() {
        totalTimeLabel.text = "00:00:00"
    }
    
    private func setupRecorder() {
        recorder.delegate = self
    }
    
    private func setupLoader() {
        do {
            loader = try FileDataLoader(fileName: "result", fileFormat: "m4a")
            let time = AudioUtils.time(from: loader.fileDuration)
            let totalTimeString = String(format: "%02d:%02d:%02d",
                                         time.minutes,
                                         time.seconds,
                                         time.milliSeconds)
            totalTimeLabel.text = totalTimeString
            try loader.loadFile(completion: { [weak self] array in
                let model = self?.buildWaveformModel(from: array, numberOfSeconds: loader.fileDuration)
                DispatchQueue.main.async {
                    self?.waveformCollectionView.load(values: model ?? [])
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
    
    private func setupWaveform() {
        waveformCollectionView.delegate = self
        waveformCollectionView.leadingLineTimeUpdaterDelegate = self
    }
    
    private func setupAudioController() {
        AudioController.sharedInstance.prepare(with: AudioUtils.defualtSampleRate)
        AudioController.sharedInstance.delegate = self
    }
}

// MARK: - Buttons - start/pause/resume

extension ViewController {
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
    
    func startOrPause() {
        
        if (recorder.isRecording) {
            recorder.pause()
//        } else if (currentlyShownTime < recorder.currentTime) {
//            startRecording(with: true)
        } else {
            if recorder.currentTime > TimeInterval(0.1) {
                recorder.resume()
            } else {
                startRecording(with: false)
            }
        }
    }
    
    private func startRecording(with overwrite: Bool) {
        do {
            try recorder.start(with: overwrite)
        } catch RecorderError.noMicrophoneAccess {
            Log.error("Microphone access not granted.")
        } catch RecorderError.directoryDeletionFailed(let error) {
            Log.error(error)
        } catch RecorderError.directoryCreationFailed(let error) {
            Log.error(error)
        } catch {
            Log.error("Unknown error.")
        }
    }
    
    private func retriveFileDataAndSet(with url: URL) {
        do {
            loader = try FileDataLoader(fileURL: url)
            let time = AudioUtils.time(from: (loader.fileDuration)!)
            let totalTimeString = String(format: "%02d:%02d:%02d",
                                         time.minutes,
                                         time.seconds,
                                         time.milliSeconds)
            totalTimeLabel.text = totalTimeString
            try loader.loadFile(completion: { [weak self] (array) in
                let model = self?.buildWaveformModel(from: array, numberOfSeconds: (self?.loader.fileDuration)!)
                DispatchQueue.main.async {
                    self?.waveformCollectionView.load(values: model ?? [])
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
                self?.retriveFileDataAndSet(with: url)
                self?.navigationController?
                    .popViewController(animated: true)
            }
        }
    }
}

extension ViewController {
    func createModel(value: CGFloat, with timeStamp: TimeInterval) -> WaveformModel {
        return WaveformModel(value: value, recordType: .first, timeStamp: timeStamp)
    }
    
    func buildWaveformModel(from samples: [Float], numberOfSeconds: Double) -> [[WaveformModel]] {
        // Liczba próbek na sekundę
        let sampleRate = Double(samples.count) / numberOfSeconds
        
        let waveformSamples = samples.enumerated()
            .map { sample in
                WaveformModel(value: CGFloat(sample.element), recordType: .first, timeStamp: Double(sample.offset) / sampleRate)
        }
        
        // Po wczytaniu z pliku wykres ma się mieścić cały na ekranie. (domyślnie mieści się 6 komórek)
        //        let numberOfCellsPerScreen: Int = 6
        //        let samplesPerCell = Int(ceil(Float(samples.count) / Float(numberOfCellsPerScreen)))
        
        let samplesPerCell = Int(ceil(Float(samples.count) / Float(numberOfSeconds)))
        
        var result = [[WaveformModel]]()
        
        for cellIndex in 0..<Int(numberOfSeconds) {
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
    
    func updatePeak(_ peak: Float, with timeStamp: TimeInterval) {
        sampleIndex = sampleIndex + 1
        self.sec = Int(sampleIndex / elementsPerSecond) + 1
        
        Assert.checkRepresentation(sec < 0, "Second value is less than 0!")
        
        //newsecon
        if values.count <= sec {
            newSecond()
        }
        
        let precision = sampleIndex % elementsPerSecond
        let model = createModel(value: CGFloat(peak), with: timeStamp)
        if (values[sec - 1].count == elementsPerSecond) {
            values[sec - 1][precision] = model
        } else {
            values[sec - 1].append(model)
        }
        
        if (values[sec - 1].count > elementsPerSecond) {
            Assert.checkRepresentation(true, "ERROR! values[sec - 1].count > elementsPerSecond")
        }
        waveformCollectionView.update(model: model, sampleIndex: sampleIndex)
        waveformCollectionView.setOffset()
    }
    
    func newSecond() {
        values.append([])
        waveformCollectionView.newSecond(values.count - 1, CGFloat(sampleIndex))
    }
}

extension ViewController: AudioControllerDelegate {
    func processSampleData(_ data: Float) {
        updatePeak(data * AudioUtils.defaultWaveformFloatModifier, with: recorder.currentTime)
    }
}

// MARK: - WaveformViewDelegate

extension ViewController: WaveformViewDelegate {
    func didScroll(_ x: CGFloat) {
        if (recorder.isRecording) {
            currentIndex = Int(x)
        }
    }
}

extension ViewController: LeadingLineTimeUpdaterDelegate {
    func timeDidChange(with time: Time) {
        let totalTimeString = String(format: "%02d:%02d:%02d",
                                     time.minutes,
                                     time.seconds,
                                     time.milliSeconds)
   
        timeLabel.text = totalTimeString

//        print("X interval: \(time.interval)")
//        print("recorder time: \(recorder.currentTime)")
//        print("-------------------------------------")
    }
}

extension ViewController: RecorderDelegate {
    func recorderStateDidChange(with state: RecorderState) {
        switch state {
        case .isRecording:
            AudioController.sharedInstance.start()
            recordButton.setTitle("Pause", for: .normal)
            if let currentIndex = self.currentIndex, (currentIndex < sampleIndex) {
                CATransaction.begin()
                sampleIndex = currentIndex
                waveformCollectionView.refresh()
                CATransaction.commit()
            }
            waveformCollectionView.isUserInteractionEnabled = false
            
        case .stopped:
            AudioController.sharedInstance.stop()
            recordButton.setTitle("Start", for: .normal)
            waveformCollectionView.isUserInteractionEnabled = true
            waveformCollectionView.onPause(sampleIndex: CGFloat(sampleIndex))
        case .paused:
            AudioController.sharedInstance.stop()
            recordButton.setTitle("Resume", for: .normal)
            waveformCollectionView.isUserInteractionEnabled = true
            waveformCollectionView.onPause(sampleIndex: CGFloat(sampleIndex))
        case .notInitialized, .initialized:
            break
        }
    }
}
