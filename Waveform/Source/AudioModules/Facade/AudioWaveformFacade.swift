//
// Created by Michał Kos on 2018-10-05.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

class AudioWaveformFacade {

    // MARK: - Private properties

    private var plotDataManager: WaveformPlotDataMangerProtocol
    private var audioModulesManager: AudioModulesManagerProtocol

    // MARK: - Public properties

    weak var delegate: AudioWaveformFacadeDelegate?
    var timeInterval: TimeInterval = 0.0

    // MARK: - Initialization

    init(plotDataManager: WaveformPlotDataManager, audioModulesManager: AudioModulesManagerProtocol) {
        self.plotDataManager = plotDataManager
        self.audioModulesManager = audioModulesManager
        self.audioModulesManager.delegate = self
        self.plotDataManager.delegate = self
    }
}

// MARK: - Access methods

extension AudioWaveformFacade: AudioWaveformFacadeProtocol {
    var resultsDirectoryURL: URL {
        return audioModulesManager.resultsDirectoryURL
    }
    var autoscrollStepWidth: CGFloat {
        return plotDataManager.autoscrollStepWidth
    }

    func loadFile(with url: URL) throws {
        try audioModulesManager.loadFile(with: url)
    }

    func recordOrPause(at timeInterval: TimeInterval) throws {
        try audioModulesManager.recordOrPause(at: timeInterval)
    }

    func finishRecording() throws {
        try audioModulesManager.finishRecording()
    }

    func playOrPause(at timeInterval: TimeInterval, completion: @escaping RethrowBlockCompletion) throws {
        try audioModulesManager.playOrPause(at: timeInterval, completion: completion)
    }

    func clearRecordings() throws {
        try audioModulesManager.clearRecordings()
    }

    func zoomIn() {
        plotDataManager.zoomIn()

        let currentPosition = plotDataManager.calculatePosition(for: timeInterval, duration: audioModulesManager.recordingDuration)
        delegate?.shiftOffset(to: currentPosition)
    }

    func zoomOut() {
        plotDataManager.zoomOut()

        let currentPosition = plotDataManager.calculatePosition(for: timeInterval, duration: audioModulesManager.recordingDuration)
        delegate?.shiftOffset(to: currentPosition)
    }

    func fileLoaded(with values: [Float], and width: CGFloat) {
        plotDataManager.fileLoaded(with: values, and: width)
    }
}

// MARK: - WaveformPlot data source

extension AudioWaveformFacade: WaveformPlotDataSource {
    func timeInterval(in waveformPlot: WaveformPlot) -> TimeInterval {
        return TimeInterval(self.plotDataManager.zoomLevel.samplesPerLayer)
    }

    func numberOfTimeIntervals(in waveformPlot: WaveformPlot) -> Int {
        return self.plotDataManager.numberOfTimeInterval
    }

    func waveformPlot(_ waveformPlot: WaveformPlot, samplesAtTimeIntervalIndex index: Int) -> [Sample] {
        return self.plotDataManager.samples(timeIntervalIndex: index)
    }

    func waveformPlot(_ waveformPlot: WaveformPlot, timeIntervalWidthAtIndex index: Int) -> CGFloat {
        return self.plotDataManager.timeIntervalWidth(index: index)
    }
}

// MARK: - WaveformPlotDataManager delegate

extension AudioWaveformFacade: WaveformPlotDataManagerDelegate {
    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, numberOfSamplesDidChange count: Int) {
    }

    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, zoomLevelDidChange level: ZoomLevel) {
        delegate?.zoomLevelDidChange(to: level)
    }
}

// MARK: - WaveformPlot delegate

extension AudioWaveformFacade: WaveformPlotDelegate {
    func waveformPlot(_ waveformPlot: WaveformPlot, contentOffsetDidChange contentOffset: CGPoint) {
    }

    func waveformPlot(_ waveformPlot: WaveformPlot, contentSizeDidChange contentSize: CGSize) {
    }

    func waveformPlot(_ waveformPlot: WaveformPlot, currentPositionDidChange position: CGFloat) {
        let validPosition = max(position, 0.0)
        plotDataManager.currentPositionChanged(to: validPosition)
        let timeInterval = plotDataManager.calculateTimeInterval(for: validPosition,
                                                                 duration: audioModulesManager.recordingDuration)
        self.timeInterval = timeInterval
        delegate?.leadingLineTimeIntervalDidChange(to: timeInterval)
    }
}

// MARK: - AudioModulesManager loader delegate

extension AudioWaveformFacade: AudioModulesManagerDelegate {
    func processSampleData(_ data: Float,
                           with mode: AudioRecordingMode,
                           at timeStamp: TimeInterval) {
        plotDataManager.processNewSample(sampleData: data, with: mode, at: timeStamp)
        delegate?.shiftOffset(to: plotDataManager.newSampleOffset)
        delegate?.audioDurationDidChange(to: timeInterval)
        delegate?.leadingLineTimeIntervalDidChange(to: timeInterval)
    }

    func recorderStateDidChange(with state: AudioRecorderState) {
        if state == .started {
            reset()
        }

        self.delegate?.recorderStateDidChange(with: state)
    }

    func playerStateDidChange(with state: AudioPlayerState) {
        self.delegate?.playerStateDidChange(with: state)
    }

    func loaderStateDidChange(with state: FileDataLoaderState) {
        self.delegate?.loaderStateDidChange(with: state)
    }

    func reset() {
        plotDataManager.reset()
    }

    func recalculateZoom(with width: CGFloat) {
        plotDataManager.recalculateZoom(for: width)
    }
}


