//
// Created by Michał Kos on 03/09/2018.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation
import UIKit

struct WaveformModel {
    let value: CGFloat
    let part: Int
    let timeStamp: TimeInterval

    init(value: CGFloat, part: Int, timeStamp: TimeInterval) {
        self.value = value
        self.part = part
        self.timeStamp = timeStamp
    }
}
