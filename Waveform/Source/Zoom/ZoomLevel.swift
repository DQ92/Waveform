//
// Created by Michał Kos on 2018-09-24.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation

struct ZoomLevel: Equatable {
    let samplePerLayer: Int
    let multiplier: Double

    var percent: String {
        return "\(Int(multiplier * 100))%"
    }
}

func ==(lhs: ZoomLevel, rhs: ZoomLevel) -> Bool {
    return lhs.samplePerLayer == rhs.samplePerLayer
}