//
// Created by Michał Kos on 29/08/2018.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation
import UIKit

class WaveformCollectionViewCell: UICollectionViewCell {

    // MARK: - Private properties

    private var baseLayer = CAShapeLayer()

    // MARK: - Initialization

    override func prepareForReuse() {
        super.prepareForReuse()

        contentView.layer.sublayers = []
        contentView.backgroundColor = nil
    }
}
