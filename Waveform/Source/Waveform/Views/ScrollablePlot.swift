//
//  ScrollablePlot.swift
//  Waveform
//
//  Created by Robert Mietelski on 30.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

protocol ScrollablePlot: class {
    var contentOffset: CGPoint { get set }
}
