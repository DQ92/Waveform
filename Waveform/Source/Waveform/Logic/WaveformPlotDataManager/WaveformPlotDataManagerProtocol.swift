//
// Created by Michał Kos on 2018-10-08.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

protocol WaveformPlotDataMangerProtocol: class {
    var delegate: WaveformPlotDataManagerDelegate? { get set }
    var autoscrollStepWidth: CGFloat { get }
    var numberOfTimeInterval: Int { get }
    var newSampleOffset: CGFloat { get }
    var currentSampleIndex: Int { get set }
    var standardTimeIntervalWidth: CGFloat { get }
    var zoomLevel: ZoomLevel { get }

    func zoomIn()
    func zoomOut()
    func reset()
    func fileLoaded(with values: [Float], and samplesPerPoint: CGFloat)
    func samples(timeIntervalIndex: Int) -> [Sample]
    func timeIntervalWidth(index: Int) -> CGFloat
    func currentPositionChanged(to position: CGFloat)
    func calculateTimeInterval(for position: CGFloat, duration: TimeInterval) -> TimeInterval
    func calculatePosition(for timeInterval: TimeInterval, duration: TimeInterval) -> CGFloat
    func processNewSample(sampleData: Float, with mode: AudioRecordingMode, at timeStamp: TimeInterval)
}
