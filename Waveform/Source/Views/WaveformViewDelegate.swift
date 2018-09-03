//
// Created by Michał Kos on 03/09/2018.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation
import UIKit

protocol WaveformViewDelegate: class {
    func didScroll(_ x: CGFloat, _ leadingLineX: CGFloat)
}

