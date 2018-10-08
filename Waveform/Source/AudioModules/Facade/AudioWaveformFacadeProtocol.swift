//
// Created by Michał Kos on 2018-10-08.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

protocol AudioWaveformFacadeProtocol: WaveformPlotDataSource, WaveformPlotDelegate {
    var timeInterval: TimeInterval { get }
    var delegate: AudioWaveformFacadeDelegate? { get set }
    var resultsDirectoryURL: URL { get }
    var autoscrollStepWidth: CGFloat { get }

    func loadFile(with url: URL) throws
    func recordOrPause(at timeInterval: TimeInterval) throws
    func finishRecording() throws
    func playOrPause(at timeInterval: TimeInterval) throws
    func clearRecordings() throws
    func zoomIn()
    func zoomOut()
    func fileLoaded(with values: [Float], and samplesPerPoint: CGFloat)
}
