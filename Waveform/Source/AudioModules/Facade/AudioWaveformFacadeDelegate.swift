//
// Created by Michał Kos on 2018-10-08.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

protocol AudioWaveformFacadeDelegate: class {
    func loaderStateDidChange(with state: FileDataLoaderState)
    func playerStateDidChange(with state: AudioPlayerState)
    func recorderStateDidChange(with state: AudioRecorderState)
    func leadingLineTimeIntervalDidChange(to timeInterval: TimeInterval)
    func audioDurationDidChange(to timeInterval: TimeInterval)
    func shiftOffset(to offset: CGFloat)
    func zoomLevelDidChange(to level: ZoomLevel)
}
