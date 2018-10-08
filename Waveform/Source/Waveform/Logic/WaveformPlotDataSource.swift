//
// Created by Michał Kos on 2018-10-08.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

protocol WaveformPlotDataSource: class {
    func numberOfTimeInterval(in waveformPlot: WaveformPlot) -> Int
    func waveformPlot(_ waveformPlot: WaveformPlot, samplesAtTimeIntervalIndex index: Int) -> [Sample]
    func waveformPlot(_ waveformPlot: WaveformPlot, timeIntervalWidthAtIndex index: Int) -> CGFloat
}