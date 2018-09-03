//
// Created by Michał Kos on 29/08/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

class LeadingLineTime {

    // MARK: - Private properties

    private weak var timeLabel: UILabel?
    private let elementsPerSecond: Int

    // MARK: - Initialization

    init(timeLabel: UILabel, elementsPerSecond: Int) {
        self.timeLabel = timeLabel
        self.elementsPerSecond = elementsPerSecond
    }

    // MARK: - Access method

    func changeTime(withXPosition position: CGFloat) {


        let seconds2 = position/CGFloat(elementsPerSecond)


        let baseSeconds = Int(position/CGFloat(elementsPerSecond))
        let seconds = (baseSeconds % 3600) % 60
        let min = (baseSeconds % 3600) / 60
        let hr = baseSeconds / 3600
        let fractionalPart = Int((seconds2 - CGFloat(Int(seconds2))) * 100)

        let totalTimeString = String(format: "%02d:%02d:%02d:%02d", hr, min, seconds, fractionalPart)

        timeLabel?.text = totalTimeString

        print("---------------------------------------")
        print("X position changed: ----\(position/CGFloat(elementsPerSecond))----")
        print("baseSeconds: ----\(fractionalPart)----")
        print("total time: ----\(totalTimeString)----")
    }
}
