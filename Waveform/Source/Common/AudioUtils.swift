//
// Created by Michał Kos on 04/09/2018.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation

class AudioUtils {
    static func toRMS(buffer: [Float], bufferSize: Int) -> Float {
        var sum: Float = 0.0
        for index in 0..<bufferSize {
            sum += buffer[index] * buffer[index]
        }
        return sqrtf(sum / Float(bufferSize))
    }
}
