import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var recordingTimeLabel: UILabel!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var waveformPlot: WaveformPlot!

    // MARK: - Private Properties
    
    private var recorder: RecorderProtocol = AVFoundationRecorder()
    private var loader: FileDataLoader!

    private var values = [[WaveformModel]]() {
        didSet {
            self.waveformPlot.waveformView.values = values
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
        setupRecorder()
        setupWaveform()
        setupAudioController()
    }

    private func setupView() {
        totalTimeLabel.text = "00:00:00"
        timeLabel.text = "00:00:00"
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

    private func setupWaveform() {
        self.waveformPlot.waveformView.delegate = self
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
                let time = CMTime(seconds: self.waveformPlot.waveformView.currentTimeInterval, preferredTimescale: 1)
                let range = CMTimeRange(start: time, duration: kCMTimeZero)
                
                recorder.resume(from: range)
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
}

extension ViewController: AudioControllerDelegate {
    func processSampleData(_ data: Float) {
        self.waveformPlot.waveformView.setValue(data * AudioUtils.defaultWaveformFloatModifier, for: recorder.currentTime)
    }
}

// MARK: - WaveformViewDelegate

extension ViewController: WaveformViewDelegate {
    func currentTimeIntervalDidChange(with timeInterval: TimeInterval) {
        timeLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
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

        case .stopped:
            AudioController.sharedInstance.stop()
            recordButton.setTitle("Start", for: .normal)
            waveformPlot.waveformView.isUserInteractionEnabled = true
            waveformPlot.waveformView.onPause()
        case .paused:
            AudioController.sharedInstance.stop()
            recordButton.setTitle("Resume", for: .normal)
            waveformPlot.waveformView.isUserInteractionEnabled = true
            waveformPlot.waveformView.onPause()
        case .notInitialized, .initialized:
            break
        }
    }
}
