//
// Created by Michał Kos on 2018-10-08.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

protocol WaveformPlotDelegate: class {
    func waveformPlot(_ waveformPlot: WaveformPlot, contentSizeDidChange contentSize: CGSize)
    func waveformPlot(_ waveformPlot: WaveformPlot, contentOffsetDidChange contentOffset: CGPoint)
    func waveformPlot(_ waveformPlot: WaveformPlot, currentPositionDidChange position: CGFloat)
}