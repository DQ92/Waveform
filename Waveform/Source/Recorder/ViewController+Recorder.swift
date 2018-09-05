
import UIKit
import AVFoundation


// TODO: - Refactor to manager

extension ViewController {
 
    func startRecording() {
        AudioController.sharedInstance.start()
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
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                suffix = suffix + 1
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
                audioRecorder.record()
                meterTimer = Timer.scheduledTimer(timeInterval: WaveformConfiguration.timeInterval, target: self, selector: #selector(self.updateAudioMeter(timer:)), userInfo: nil, repeats: true) //zatrzymywać timer na pauzie
                
                record_btn_ref.setTitle("Pause", for: .normal)
                isRecording = true
            } catch let error {
                log("\(error.localizedDescription)")
            }
        } else {
            log("Don't have access to use your microphone.")
        }
    }
    
    func list(directory at: URL) -> Void {
        do {
            let listing = try FileManager.default.contentsOfDirectory(atPath: at.path)
        
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
        } catch {
        
        }
    }
    
    @IBAction func recordAt(_ sender: UIButton) {
        stop()
        
//        crop(sourceURL: getFileUrl(), startTime: 0, endTime: time) { (url) in
//            self.suffix = self.suffix + 1
//        }
    }
    
    func crop(sourceURL: URL, startTime: Double, endTime: Double, completion: ((_ outputUrl: URL) -> Void)? = nil) {
        let asset = AVAsset(url: sourceURL)
        let length = assetDuration(asset)
        log("length asset to crop: \(length) seconds")
        
        if (endTime > Double(length)) {
            log("Error! endTime > length")
        }
        
        var outputURL = documentsURL.appendingPathComponent(tempDictName)
        do {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
        } catch let error {
            log(error)
        }
        let preferredTimescale = WaveformConfiguration.preferredTimescale
        let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: preferredTimescale), end: CMTime(seconds: endTime, preferredTimescale: preferredTimescale))
        
        try? fileManager.removeItem(at: outputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return
        }
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
            var totalTime: CMTime = kCMTimeZero
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
    }
    
    func getAllAudioParts() -> [AVAsset] {
        do {
            let at = documentsURL.appendingPathComponent(tempDictName)
            var listing = try FileManager.default.contentsOfDirectory(atPath: at.path)
            var assets = [AVAsset]()
            listing = listing.sorted(by: { $0 < $1 })
            totalDuration = 0
            
            for file in listing {
                let fileURL = at.appendingPathComponent(file)
                print("FILE URL: \(fileURL)")
                let asset = AVAsset(url: fileURL)
                totalDuration += assetDuration(asset)
                assets.append(asset)
            }
            return assets
        } catch {
            return []
        }
    }
}
