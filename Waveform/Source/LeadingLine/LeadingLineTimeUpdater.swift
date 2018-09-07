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
        let timeStamp = position / CGFloat(elementsPerSecond)
        let time = AudioUtils.time(from: TimeInterval(timeStamp))
        delegate?.timeDidChange(with: time)
    }
}

protocol LeadingLineTimeUpdaterDelegate: class {
    func timeDidChange(with time: Time)
}


