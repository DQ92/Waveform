//
// Created by Michał Kos on 2018-09-24.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

struct ZoomLevel: Equatable {
    let samplesPerLayer: Int
    let multiplier: Double

    var percent: String {
        return "\(Int(multiplier * 100))%"
    }
}

func ==(lhs: ZoomLevel, rhs: ZoomLevel) -> Bool {
    return lhs.samplesPerLayer == rhs.samplesPerLayer
}