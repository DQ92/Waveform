//
// Created by Michał Kos on 2018-09-24.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

class TimeIntervalCalculator {
    static func calculateTimeInterval(for position: CGFloat,
                                      samplePerLayer: Int,
                                      elementsPerSecond: Int) -> Double {
        let timeInterval = (Double(position) / Double(elementsPerSecond)) * Double(samplePerLayer)
        return timeInterval
    }

    static func calculateXPosition(for timeInterval: TimeInterval,
                                   samplePerLayer: Int,
                                   elementsPerSecond: Int) -> CGFloat {
        let position = CGFloat(timeInterval * Double(elementsPerSecond) / Double(samplePerLayer))
        return position
    }
}
