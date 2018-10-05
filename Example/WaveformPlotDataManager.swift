//
//  WaveformPlotDataManager.swift
//  Waveform
//
//  Created by Robert Mietelski on 26.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

protocol WaveformPlotDataMangerProtocol: class {
    var delegate: WaveformPlotDataManagerDelegate? { get set }
    var autoscrollStepWidth: CGFloat { get }
    var numberOfTimeInterval: Int { get }
    var newSampleOffset: CGFloat { get }
    var currentSampleIndex: Int { get set }
    var standardTimeIntervalWidth: CGFloat { get }

    func zoomIn()
    func zoomOut()
    func reset()
    func fileLoaded(with values: [Float], and samplesPerPoint: CGFloat)
    func samples(timeIntervalIndex: Int) -> [Sample]
    func timeIntervalWidth(index: Int) -> CGFloat
    func currentPositionChanged(to position: CGFloat)
    func calculateTimeInterval(for position: CGFloat, duration: TimeInterval) -> TimeInterval
    func processNewSample(sampleData: Float, with mode: AudioRecordingMode, at timeStamp: TimeInterval)
}

protocol WaveformPlotDataManagerDelegate: class {
    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, numberOfSamplesDidChange count: Int)
    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, zoomLevelDidChange level: ZoomLevel)
}

class WaveformPlotDataManager {

    // MARK: - Public properties

    var numberOfLayers: Int {
        return Int(ceil(CGFloat(self.data.count) / CGFloat(self.zoom.level.samplesPerLayer)))
    }

    var numberOfTimeInterval: Int {
        return Int(ceil(CGFloat(self.numberOfLayers) / CGFloat(self.layersPerTimeInterval)))
    }

    var standardTimeIntervalWidth: CGFloat {
        return CGFloat(self.layersPerTimeInterval) * self.layerWidth
    }

    var sampleWidth: CGFloat {
        return self.layerWidth / CGFloat(self.zoom.level.samplesPerLayer)
    }

    var zoomLevel: ZoomLevel {
        return self.zoom.level
    }

    var numberOfSamples: Int {
        return self.data.count
    }

    var newSampleOffset: CGFloat {
        return CGFloat(currentSampleIndex + 1) * self.sampleWidth
    }

    var stepWidth: CGFloat {
        return CGFloat(layersPerTimeInterval) / CGFloat((100 * zoomLevel.samplesPerLayer))
    }

    var currentSampleIndex: Int = 0
    let layersPerTimeInterval: Int = WaveformConfiguration.microphoneSamplePerSecond
    let layerWidth: CGFloat = 1.0

    weak var delegate: WaveformPlotDataManagerDelegate?

    // MARK: - Private properties

    private var updateIndicatorTimer: Timer?
    private var data: [WaveformModel] = []
    private var zoom: Zoom = Zoom()

    // MARK: - Initialization

    init() {
    }

    // MARK: - Access methods

    func samples(timeIntervalIndex: Int) -> [Sample] {
        let samplesPerSecond = self.layersPerTimeInterval * self.zoom.level.samplesPerLayer
        let startIndex = timeIntervalIndex * samplesPerSecond
        let endIndex = min(startIndex + samplesPerSecond, self.data.count) - 1

        let subarray = Array(self.data[startIndex...endIndex])
        let range = 0..<Int(ceil(CGFloat(subarray.count) / CGFloat(self.zoom.level.samplesPerLayer)))
        var samples: [Sample] = []

        for index in range {
            let startIndex = index * self.zoom.level.samplesPerLayer
            let endIndex = min(startIndex + self.zoom.level.samplesPerLayer, subarray.count) - 1
            let range = startIndex...endIndex

            let models = subarray[range]
            let sum = models.map { $0.value }.reduce(0.0, +)
            let average = sum / CGFloat(range.count)

            samples.append(Sample(value: average,
                                  color: WaveformColor.color(for: models.last!.mode),
                                  width: self.layerWidth))
        }
        return samples
    }

    func timeIntervalWidth(index: Int) -> CGFloat {
        let samplesPerSecond = self.layersPerTimeInterval * self.zoom.level.samplesPerLayer
        let startIndex = index * samplesPerSecond
        let numberOfLayer = Int(ceil(CGFloat(self.data.count - startIndex) / CGFloat(self.zoom.level.samplesPerLayer)))

        return CGFloat(min(numberOfLayer, self.layersPerTimeInterval)) * self.layerWidth
    }

    func reset() {
        self.zoom = Zoom()
        self.data = []
        currentSampleIndex = 0
        self.delegate?.waveformPlotDataManager(self, zoomLevelDidChange: self.zoom.level)
        self.delegate?.waveformPlotDataManager(self, numberOfSamplesDidChange: self.data.count)
    }
}

// MARK: - Values

extension WaveformPlotDataManager {
    func loadData(from values: [Float]) {
        self.data = values.enumerated().map { [unowned self] sample in
            WaveformModel(value: CGFloat(sample.element),
                          mode: .normal,
                          timeStamp: TimeInterval(sample.offset / self.layersPerTimeInterval))
        }
        self.delegate?.waveformPlotDataManager(self, numberOfSamplesDidChange: self.data.count)
    }

    func setData(data: WaveformModel) {
        if currentSampleIndex == self.data.count {
            self.data.append(data)
        } else {
            self.data[currentSampleIndex] = data
        }
        self.delegate?.waveformPlotDataManager(self, numberOfSamplesDidChange: self.data.count)
    }
}

// MARK: - Zoom

extension WaveformPlotDataManager {
    func loadZoom(from samplesPerPoint: CGFloat) {
        self.zoom = Zoom(samplesPerPoint: samplesPerPoint)
        self.delegate?.waveformPlotDataManager(self, zoomLevelDidChange: self.zoom.level)
    }

    func zoomIn() {
        self.zoom.in()
        self.delegate?.waveformPlotDataManager(self, zoomLevelDidChange: self.zoom.level)
    }

    func zoomOut() {
        self.zoom.out()
        self.delegate?.waveformPlotDataManager(self, zoomLevelDidChange: self.zoom.level)
    }
}

// MARK: - Access

extension WaveformPlotDataManager: WaveformPlotDataMangerProtocol {
    func currentPositionChanged(to position: CGFloat) {
        currentSampleIndex =  min(Int(position / sampleWidth), numberOfSamples)
    }

    func processNewSample(sampleData: Float, with mode: AudioRecordingMode, at timeStamp: TimeInterval) {
        let data = WaveformModel(value: CGFloat(sampleData * AudioUtils.defaultWaveformFloatModifier),
                                 mode: mode,
                                 timeStamp: timeStamp)
        setData(data: data)
    }

    func fileLoaded(with values: [Float], and samplesPerPoint: CGFloat) {
        loadData(from: values)
        loadZoom(from: samplesPerPoint)
    }

    func calculateTimeInterval(for position: CGFloat, duration: TimeInterval) -> TimeInterval {
        let plotWidth = CGFloat(self.data.count) * self.sampleWidth
        if plotWidth > 0 {
            let multiplier = position / plotWidth
            return Double(multiplier) * duration
        }
        return 0.0
    }

    func calculatePosition(for timeInterval: TimeInterval) -> CGFloat {
        return CGFloat(timeInterval * TimeInterval(self.layersPerTimeInterval) / TimeInterval(self.zoom.level.samplesPerLayer))
    }
}
