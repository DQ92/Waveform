//
// Created by Michał Kos on 29/08/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

class LeadingLineTimeUpdater {

    // MARK: - Private properties

    private let elementsPerSecond: Int

    // MARK: - Public properties

    weak var delegate: LeadingLineTimeUpdaterDelegate?

    // MARK: - Initialization

    init(elementsPerSecond: Int) {
        self.elementsPerSecond = elementsPerSecond
    }

    // MARK: - Access method

    func changeTime(withX position: CGFloat) {
        let timeStamp = position/CGFloat(elementsPerSecond)
        let baseSeconds = Int(position/CGFloat(elementsPerSecond))

        let seconds = (baseSeconds % 3600) % 60
        let minutes = (baseSeconds % 3600) / 60
        let hours = baseSeconds / 3600
        let milliSeconds = Int((timeStamp - CGFloat(Int(timeStamp))) * 100)
        let time = Time(hours: hours, minutes: minutes, seconds: seconds, milliSeconds: milliSeconds)

        delegate?.timeDidChange(with: time)

//        print("---------------------------------------")
//        print("X position changed: ----\(position/CGFloat(elementsPerSecond))----")
//        print("baseSeconds: ----\(fractionalPart)----")
//        print("total time: ----\(totalTimeString)----")
    }
}

protocol LeadingLineTimeUpdaterDelegate: class {
    func timeDidChange(with time: Time)
}

struct Time {
    let hours: Int
    let minutes: Int
    let seconds: Int
    let milliSeconds: Int
}
