//
// Created by Michał Kos on 2018-10-05.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

protocol AudioWaveformFacadeDelegate: class {
    func leadingLineTimeIntervalDidChange(to timeInterval: TimeInterval)
    func audioDurationDidChange(to timeInterval: TimeInterval)
    func shiftOffset(to offset: CGFloat)
    func zoomLevelDidChange(to level: ZoomLevel)
}

protocol AudioWaveformFacadeProtocol: WaveformPlotDataSource, WaveformPlotDelegate  {
    var timeInterval: TimeInterval  { get }
    var plotDataManager: WaveformPlotDataMangerProtocol { get }
    var audioModulesManager: AudioModulesManagerProtocol { get }
    var delegate: AudioWaveformFacadeDelegate? { get set }
}

class AudioWaveformFacade: AudioWaveformFacadeProtocol {
    let plotDataManager: WaveformPlotDataMangerProtocol
    var audioModulesManager: AudioModulesManagerProtocol
    weak var delegate: AudioWaveformFacadeDelegate?
    var timeInterval: TimeInterval = 0.0

    // MARK: - Initialization

    init(plotDataManager: WaveformPlotDataManager, audioModulesManager: AudioModulesManagerProtocol) {
        self.plotDataManager = plotDataManager
        self.audioModulesManager = audioModulesManager
        self.audioModulesManager.fileLoaderDelegate = self
    }
}

// MARK: - WaveformPlot data source

extension AudioWaveformFacade {
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

// MARK: - WaveformPlot delegate

extension AudioWaveformFacade {
    func waveformPlot(_ waveformPlot: WaveformPlot, contentOffsetDidChange contentOffset: CGPoint) {

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

extension AudioWaveformFacade: AudioModulesManagerLoaderDelegate {
    func processSampleData(_ data: Float,
                           with mode: AudioRecordingMode,
                           at timeStamp: TimeInterval) {
        plotDataManager.processNewSample(sampleData: data, with: mode, at: timeStamp)
        delegate?.shiftOffset(to: plotDataManager.newSampleOffset)
        delegate?.audioDurationDidChange(to: timeInterval)
        delegate?.leadingLineTimeIntervalDidChange(to: timeInterval)
    }
}

extension AudioWaveformFacade {
    func waveformPlot(_ manager: WaveformPlotDataManager, numberOfSamplesDidChange count: Int) {
    }

    func waveformPlot(_ manager: WaveformPlotDataManager, zoomLevelDidChange level: ZoomLevel) {
        delegate?.zoomLevelDidChange(to: level)
    }
}