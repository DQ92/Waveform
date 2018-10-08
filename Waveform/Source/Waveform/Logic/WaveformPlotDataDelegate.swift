//
// Created by Michał Kos on 2018-10-08.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

protocol WaveformPlotDataManagerDelegate: class {
    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, numberOfSamplesDidChange count: Int)
    func waveformPlotDataManager(_ manager: WaveformPlotDataManager, zoomLevelDidChange level: ZoomLevel)
}
