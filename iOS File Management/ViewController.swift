
import AVFoundation
import UIKit

let timeInterval: TimeInterval = (TimeInterval(6 / Float(UIScreen.main.bounds.width)))
var viewWidth: CGFloat = 0
var partOfView: CGFloat = 0 // 1/6


class ViewController: UIViewController, AVAudioRecorderDelegate {

    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let tempDirectoryURL = FileManager.default.temporaryDirectory;
    let libraryDirectoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: .userDomainMask).first!
    
    @IBOutlet var recordingTimeLabel: UILabel!
    @IBOutlet var record_btn_ref: UIButton!
    @IBOutlet weak var peakConstraint: NSLayoutConstraint!
    @IBOutlet weak var maxHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var waveform: WaveformView!
    @IBOutlet weak var waveformRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewWaveform: CollectionViewWaveform!
    @IBOutlet weak var collectionViewRightConstraint: NSLayoutConstraint!
    
    var values = [[CGFloat]]()
    let vLayer = CAShapeLayer()
    let max: Float = 120
    var audioRecorder: AVAudioRecorder!
    var meterTimer:Timer!
    var isAudioRecordingGranted: Bool = true
    var idx = 0
    var sec: Int = 0 {
        didSet {
            if(sec != oldValue) {
                newSecond()
            }
        }
    }
    
    let padding: CGFloat = 0
    private var elementsPerSecond: Int {
        return Int((UIScreen.main.bounds.width) / 6)
    }
    
    var isRecording = false {
        didSet {
            if(isRecording) {
//                collectionViewRightConstraint.constant = self.view.frame.width / 2
//                waveformRightConstraint.constant = self.view.frame.width / 2
//                waveform.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
//                waveform.isUserInteractionEnabled = false
                collectionViewWaveform.isUserInteractionEnabled = false
            } else {
//                waveformRightConstraint.constant = waveform.padding
//                waveform.isUserInteractionEnabled = true
//                collectionViewRightConstraint.constant = self.padding
//                waveform.onPause()
                collectionViewWaveform.isUserInteractionEnabled = true
                
                let halfOfCollectionViewWidth = collectionViewWaveform.bounds.width / 2
                let currentX = CGFloat(idx)
                
                if currentX < halfOfCollectionViewWidth {
                    collectionViewWaveform.contentInset = UIEdgeInsetsMake(0, currentX, 0, halfOfCollectionViewWidth + currentX)
                    collectionViewWaveform.contentSize = CGSize(width: collectionViewWaveform.bounds.width + currentX, height: collectionViewWaveform.bounds.height)
                } else {
                    collectionViewWaveform.contentInset = UIEdgeInsetsMake(0, halfOfCollectionViewWidth, 0, halfOfCollectionViewWidth)
                }
            }
        }
    }
    var suffix: Int = 0
    private let tempDictName = "temp_audio"
    let fileManager = FileManager.default
    var isMovedWhenPaused: Bool = false // gdy przesunie seek bara to ustawić na true
    var totalDuration: Float = 0 {
        didSet {
            totalTimeLabel.text = "\(totalDuration + currentDuration) sec."
        }
    }
    var currentDuration: Float = 0
    private let preferredTimescale: CMTimeScale = 1000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        removeTempDict()
        addVerticalLayer()
        maxHeightConstraint.constant = CGFloat(max)
        createDictInTemp()
        
        viewWidth = UIScreen.main.bounds.width
        partOfView = viewWidth / 6
        
        collectionViewWaveform.register(WaveformCollectionViewCell.self, forCellWithReuseIdentifier: "collectionViewCell")
        collectionViewWaveform.dataSource = self
        collectionViewWaveform.delegate = self
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: partOfView, height: 100)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        layout.scrollDirection = .horizontal
        collectionViewWaveform.collectionViewLayout = layout
        collectionViewWaveform.reloadData()
        collectionViewWaveform.scrollTo(direction: .Left)
    }

    func listFiles() {
        list(directory: documentsURL.appendingPathComponent(tempDictName))
    }
    
    func getFileUrl() -> URL {
        let filename = "rec_\(suffix).m4a"
        let dict = documentsURL.appendingPathComponent(tempDictName)
        let filePath = dict.appendingPathComponent(filename)
        return filePath
    }
    
    func removeTempDict() {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(tempDictName)")
        do {
            try fileManager.removeItem(at: dictPath)
        } catch {
            log("Couldn't removeItem \(dictPath)")
        }
    }
    
    func createDictInTemp() {
        let fileManager = FileManager.default
        let dictPath = documentsURL.appendingPathComponent("\(tempDictName)")
        if !fileManager.fileExists(atPath: dictPath.path) {
            do {
                try fileManager.createDirectory(atPath: dictPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                log("Couldn't create document directory")
            }
        }
        log("Document directory is \(dictPath)")
    }
    
    func log(_ val: Any) {
        print(val)
    }
    
    @IBAction func sliderDidChanged(_ sender: UISlider) {
        isMovedWhenPaused = true
//        log("Slider value: \(sender.value)")
    }
    
    func getAllAudioParts() -> [AVAsset] {
        let at = documentsURL.appendingPathComponent(tempDictName)
        var listing = try! FileManager.default.contentsOfDirectory(atPath: at.path)
        var assets = [AVAsset]()
        listing = listing.sorted(by: { $0 < $1})
        totalDuration = 0
        
        for file in listing {
            let fileURL = at.appendingPathComponent(file)
            print("FILE URL: \(fileURL)")
            let asset = AVAsset(url: fileURL)
            totalDuration += assetDuration(asset)
            assets.append(asset)
        }
        
        slider.maximumValue = totalDuration + currentDuration
        log("slider.maximumValue: \(slider.maximumValue)")
        return assets
    }
}



//MARK - buttons - start/pause/resume
extension ViewController {
   
    @IBAction func startRecording(_ sender: UIButton) {
        startOrPause()
    }
    
    func startOrPause() {
        if(isRecording) {
            pause()
        } else if(isMovedWhenPaused) {
            stop()
        }  else {
            if let curTime = audioRecorder?.currentTime, curTime > TimeInterval(0.1) {
                resume()
            } else {
                startRecording()
            }
        }
    }
    
    func stop() {
        log("stopped")
        
        isMovedWhenPaused = false
        record_btn_ref.setTitle("Start", for: .normal)
        isRecording = false
        audioRecorder?.stop()
        meterTimer.invalidate()
        audioRecorder = nil
        log("recorded successfully.")
        listFiles()
        _ = getAllAudioParts()
    }
    
    func resume() {
        log("Resumed")
        audioRecorder.record()
        record_btn_ref.setTitle("Pause", for: .normal)
        isRecording = true
    }
    
    func pause() {
        log("Paused")
        record_btn_ref.setTitle("Resume", for: .normal)
        isRecording = false
        audioRecorder.pause()
        listFiles()
        
        _ = getAllAudioParts()
    }
    
    func startRecording() {
        if isAudioRecordingGranted { //sprawdzać wcześniej!
            log("startRecording")
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
                ]
                suffix = suffix + 1
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
                audioRecorder.record()
                meterTimer = Timer.scheduledTimer(timeInterval: timeInterval, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true) //zatrzymywać timer na pauzie
                
                record_btn_ref.setTitle("Pause", for: .normal)
                isRecording = true
            } catch let error {
                log("\(error.localizedDescription)")
            }
        } else {
            log("Don't have access to use your microphone.")
        }
    }
    
    func updatePeak(_ peak: Float, _ timeInterval: Int) {
        // -160 minimum -> 0
        // 0 -> max
        let _peak: Float = (-1) * peak
        var value: Float = max - _peak
        value = value > 1 ? value : 4
        
//        if(Int(value) % 10 == 0) {
            update(CGFloat(value))
//        }
        
        peakConstraint.constant = CGFloat(value)
//        waveform.averagePower = value
//        if(waveform.x < CGFloat(self.view.bounds.width / 2)) {
//            vLayer.frame = CGRect(x: CGFloat(waveform.x + 1), y: CGFloat(self.waveform.frame.origin.y), width: 1, height: CGFloat(self.waveform.bounds.height))
//        }
    }
    
    func addVerticalLayer() {
        vLayer.frame = CGRect(x: 0, y: Int(self.waveform.frame.origin.y), width: 1, height: Int(self.waveform.bounds.height))
        vLayer.backgroundColor = UIColor.blue.cgColor
        vLayer.lineWidth = 1
        view.layer.addSublayer(vLayer)
    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        stop()
        
        merge(assets: getAllAudioParts())
    }
}




//MARK - buttons - start/pause/resume
extension ViewController {
    
    @objc func updateAudioMeter(timer: Timer) {
        if audioRecorder.isRecording {
            let hr = Int((audioRecorder.currentTime / 60) / 60)
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
            let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
            recordingTimeLabel.text = totalTimeString
            currentDuration = Float(sec)
            let t = totalDuration + currentDuration
            totalTimeLabel.text = "\(t) sec."
            audioRecorder.updateMeters()
            let val = audioRecorder.averagePower(forChannel: 0) - 60
            updatePeak(val, idx)
            idx = idx + 1
        }
    }
    
    @IBAction func recordAt(_ sender: UIButton) {
        stop()
        
        let time: TimeInterval = TimeInterval(slider.value);
        sender.setTitle("Crop at... \(time) sec", for: .normal)
        
        crop(sourceURL: getFileUrl(), startTime: 0, endTime: time) { (url) in
            self.suffix = self.suffix + 1
        }
    }
    
    func crop(sourceURL: URL, startTime: Double, endTime: Double, completion: ((_ outputUrl: URL) -> Void)? = nil) {
        let asset = AVAsset(url: sourceURL)
        let length = assetDuration(asset)
        log("length asset to crop: \(length) seconds")
        
        if(endTime > Double(length)) {
            log("Error! endTime > length")
        }
        
        var outputURL = documentsURL.appendingPathComponent(tempDictName)
        do {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
        } catch let error {
            log(error)
        }
        
        let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: self.preferredTimescale), end: CMTime(seconds: endTime, preferredTimescale: self.preferredTimescale))
        
        try? fileManager.removeItem(at: outputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                self.log("CROPPED exported at \(outputURL)")
                completion?(outputURL)
            case .failed:
                self.log("failed \(exportSession.error.debugDescription)")
            case .cancelled:
                self.log("cancelled \(exportSession.error.debugDescription)")
            default: break
            }
        }
    }

    func merge(assets: [AVAsset]) {
        let at = documentsURL.appendingPathComponent(tempDictName)

        if assets.count > 1 {
            print("\n----------------------------")
            print("MERGE: \(at.path)")
        
            var atTimeM: CMTime = kCMTimeZero
            let composition: AVMutableComposition = AVMutableComposition()
            var totalTime : CMTime = kCMTimeZero
            let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

            for asset in assets {
                do {
                    if asset == assets.first {
                        atTimeM = kCMTimeZero
                    } else {
                        atTimeM = totalTime // <-- Use the total time for all the audio so far.
                    }
                    
                    log("Total Time: \(totalTime)")
                    if let track = asset.tracks(withMediaType: AVMediaType.audio).first {
                    
                        try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration),
                                                   of: track,
                                                   at: atTimeM)
                        totalTime = CMTimeAdd(totalTime, asset.duration)
                    } else {
                        log("error!!")
                    }
                } catch let error as NSError {
                    log("error while merging: \(error)")
                }
            }
            
            let finalURL = at.appendingPathComponent("result.m4a")
            log("EXPORTING MERGE....\(finalURL)")
            
            if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
                exportSession.outputURL = finalURL
                exportSession.outputFileType = .mp4
                    exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        print("exported at \(finalURL)")
                    case .failed:
                        print("failed \(exportSession.error.debugDescription)")
                    case .cancelled:
                        print("cancelled \(exportSession.error.debugDescription)")
                    default: break
                    }
                }
            }
        } else {
            print("Brak plików w \(at.path)")
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        log("audioRecorderDidFinishRecording")
    }
    
    func assetDuration(_ asset: AVAsset) -> Float {
        return Float(asset.duration.value) / Float(asset.duration.timescale)
    }
    
    func list(directory at: URL) -> Void {
        let listing = try! FileManager.default.contentsOfDirectory(atPath: at.path)
        if listing.count > 0 {
            print("\n----------------------------")
            print("LISTING: \(at.path) \n")
            for file in listing {
                print("File: \(file.debugDescription)")
            }
            print("")
            print("----------------------------\n")
        } else {
            print("Brak plików w \(at.path)")
        }
    }

}


extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func newSecond() {
        values.append([])
        UIView.performWithoutAnimation {
            collectionViewWaveform.performBatchUpdates({
                self.collectionViewWaveform.insertSections(IndexSet([values.count-1]))
            }) { (done) in
                self.setOffset()
            }
        }
    }
    
    private func updateCell(_ cell: UICollectionViewCell, _ x: CGFloat, _ value: CGFloat) {
        let layerY = CGFloat(cell.bounds.size.height / 2)
        let upLayer = CAShapeLayer()
        upLayer.frame = CGRect(x: x, y: layerY, width: 1, height: -value)
        upLayer.backgroundColor = UIColor.red.cgColor
        upLayer.lineWidth = 1
        cell.contentView.layer.addSublayer(upLayer)
        let downLayer = CAShapeLayer()
        downLayer.frame = CGRect(x: x, y: layerY, width: 1, height: value)
        downLayer.backgroundColor = UIColor.orange.cgColor
        downLayer.lineWidth = 1
        cell.contentView.layer.addSublayer(downLayer)
        setOffset()
    }
    
    func setOffset() {
        let x = CGFloat(idx)
        if(x > CGFloat(self.view.bounds.width / 2) && isRecording) {
            collectionViewWaveform.setContentOffset(CGPoint(x: x - CGFloat(self.view.bounds.width / 2), y: 0), animated: false)
        }
    }
    
    func update(_ value: CGFloat) {
        self.sec = Int(idx / elementsPerSecond) + 1
        values[sec - 1].append(value)
//        print("SEKUNDA: \(sec)| value: \(value) | collectionViewWaveform.numberOfSections: \(collectionViewWaveform.numberOfSections)")
        let lastCellIdx = IndexPath(row: 0, section: collectionViewWaveform.numberOfSections - 1)
        if let lastCell = collectionViewWaveform.cellForItem(at: lastCellIdx) {
            let x = CGFloat(idx%elementsPerSecond)
            updateCell(lastCell, x, value)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return values.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: elementsPerSecond, height: 100)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! WaveformCollectionViewCell
        
        let second = indexPath.section
        let valuesInSecond: [CGFloat] = values[second]
    
        if(valuesInSecond.count >= elementsPerSecond) {
            for x in 0..<valuesInSecond.count {
                updateCell(cell, CGFloat(x), valuesInSecond[x])
            }
        }
        return cell
    }
}


class WaveformCollectionViewCell: UICollectionViewCell {
    
    var baseLayer = CAShapeLayer()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        contentView.layer.sublayers = []
        contentView.backgroundColor = nil
    }
}


