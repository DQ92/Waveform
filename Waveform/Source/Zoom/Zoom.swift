//
//  Zoom.swift
//  Waveform
//
//  Created by Robert Mietelski on 20.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

struct Zoom {

    // MARK: - Public properties

    var isMinimum: Bool {
        return self.currentLevel == self.levels.count - 1
    }

    var isMaximum: Bool {
        return self.currentLevel == 0
    }

    var numberOfLevels: Int {
        return self.levels.count
    }

    var value: Int {
        return self.levels[self.currentLevel].value
    }

    var multiplier: Double {
        return self.levels[self.currentLevel].multiplier
    }

    // MARK: - Private properties

    private var levels: [ZoomLevel] = []
    private var currentLevel: Int = 0

    // MARK: - Initialization

    init(samplesPerPoint: CGFloat = 1.0, multipliers: [Double] = AudioUtils.defaultZoomMultipliers) {
        self.levels = generateZoomLevels(for: samplesPerPoint, and: multipliers)
    }

    // Access methods

    mutating func `in`() {
        if !self.isMaximum {
            self.currentLevel -= 1
        }
    }

    mutating func out() {
        if !self.isMinimum {
            self.currentLevel += 1
        }
    }

    // MARK: - Helper methods

    private func generateZoomLevels(for density: CGFloat, and multipliers: [Double]) -> [ZoomLevel] {
        let noZoomLevel = ZoomLevel(value: 1, multiplier: 1)
        let maxZoomValue = Int(ceil(density))
        let intermediateAndMaxZoomLevels = calculateIntermediateAndMaxZoomLevels(from: maxZoomValue, and: multipliers)
        var zoomLevelsArray = [noZoomLevel]
        zoomLevelsArray.append(contentsOf: intermediateAndMaxZoomLevels)

        return zoomLevelsArray
    }

    private func calculateIntermediateAndMaxZoomLevels(from max: Int, and multipliers: [Double]) -> [ZoomLevel] {
        var intermediateZoomLevels = multipliers.filter {
                                                    $0 < 1.0
                                                }
                                                .map {
                                                    ZoomLevel(value: Int($0 != 0.0 ? $0 : 1.0 * Double(max)),
                                                              multiplier: $0)
                                                }
                                                .filter {
                                                    $0.value > 1
                                                }
                                                .sorted {
                                                    $0.multiplier > $1.multiplier
                                                }
        intermediateZoomLevels.removeDuplicates()
        return intermediateZoomLevels
    }
}

struct ZoomLevel: Equatable {
    let value: Int
    let multiplier: Double

    var percent: String {
        return "\(multiplier * 100)%"
    }
}

func ==(lhs: ZoomLevel, rhs: ZoomLevel) -> Bool {
    return lhs.value == rhs.value
}

extension Array where Element: Equatable {
    mutating func removeDuplicates() {
        var result = [Element]()
        for value in self {
            if !result.contains(value) {
                result.append(value)
            }
        }
        self = result
    }
}
