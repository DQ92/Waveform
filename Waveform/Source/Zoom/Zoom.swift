//
//  Zoom.swift
//  Waveform
//
//  Created by Robert Mietelski on 20.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class Zoom {

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

    var level: ZoomLevel {
        return self.levels[currentLevel]
    }

    // MARK: - Private properties

    private var levels: [ZoomLevel] = []
    private var currentLevel: Int = 0

    // MARK: - Initialization

    init(samplesPerPoint: CGFloat = 1.0, multipliers: [Double] = AudioUtils.defaultZoomMultipliers) {
        self.levels = generateZoomLevels(for: samplesPerPoint, and: multipliers)
    }

    // Access methods

    func `in`() {
        if !self.isMaximum {
            self.currentLevel -= 1
        }
    }

    func out() {
        if !self.isMinimum {
            self.currentLevel += 1
        }
    }

    func reset() {
        self.currentLevel = 0
    }

    func changeSamplesPerPoint(_ samplesPerPoint: CGFloat, multipliers: [Double] = AudioUtils
            .defaultZoomMultipliers) {
        self.levels = generateZoomLevels(for: samplesPerPoint, and: multipliers)
    }

    // MARK: - Helper methods

    private func generateZoomLevels(for density: CGFloat, and multipliers: [Double]) -> [ZoomLevel] {
        let maxZoomValue = Int(ceil(density))
        let zoomLevels = calculateZoomLevels(from: maxZoomValue, and: multipliers)
        return zoomLevels
    }

    private func calculateZoomLevels(from max: Int, and multipliers: [Double]) -> [ZoomLevel] {
        let temporaryZoomLevels: [ZoomLevel] = multipliers.map {
                                                              return self.createZoomLevel(with: max, and: $0)
                                                          }
                                                          .filter {
                                                              $0.samplesPerLayer >= 1
                                                          }
                                                          .sorted {
                                                              $0.multiplier > $1.multiplier
                                                          }
        return retrieveValidZoomLevels(from: temporaryZoomLevels)
    }

    private func retrieveValidZoomLevels(from zoomLevels: [ZoomLevel]) -> [ZoomLevel] {
        let validZoomLevels = zoomLevels.enumerated()
                                        .filter {
                                            let case1 = $0.offset == zoomLevels.startIndex
                                            let case2 = $0.element != zoomLevels.first && $0.element != zoomLevels.last
                                            let case3 = $0.offset == zoomLevels.endIndex - 1 && $0.element !=
                                                    zoomLevels.first
                                            return case1 || case2 || case3
                                        }
                                        .map {
                                            $0.element
                                        }
        return validZoomLevels
    }

    private func createZoomLevel(with maxSamplePerLayer: Int, and multiplier: Double) -> ZoomLevel {
        var countingMultiplier: Double = 1.0 - multiplier
        var multiplierToDisplay = multiplier
        if countingMultiplier == 0.0 {
            countingMultiplier = 1.0 / Double(maxSamplePerLayer)
            multiplierToDisplay = 1.0
        }
        return ZoomLevel(samplesPerLayer: Int(ceil(countingMultiplier * Double(maxSamplePerLayer))),
                         multiplier: multiplierToDisplay)
    }
}