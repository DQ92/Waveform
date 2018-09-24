//
// Created by Michał Kos on 29/08/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import AVFoundation

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

    func changeTime(withX position: CGFloat, and samplePerLayer: Int) {
        let timeInterval = (Double(position) / Double(elementsPerSecond)) * Double(samplePerLayer)
        delegate?.timeIntervalDidChange(with: timeInterval)
    }
}

protocol LeadingLineTimeUpdaterDelegate: class {
    func timeIntervalDidChange(with timeInterval: TimeInterval)
}
