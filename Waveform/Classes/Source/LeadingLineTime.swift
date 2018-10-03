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
//        print("---------------------------------------")
//        print("X position changed: \(position/CGFloat(elementsPerSecond))")
    }

}
