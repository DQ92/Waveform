//
// Created by Michał Kos on 03/09/2018.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation
import UIKit

class WaveformColor {
    static func colors(model: WaveformModel) -> (UIColor, UIColor) {
        var part: CGFloat
        switch model.recordType {
        case .first:
            part = 0
        case .ovveride(let turn):
            part = CGFloat(turn)
        default:
            part = 0
        }
        
        let rand: CGFloat = part * 25
        let upColor = UIColor(red: rand / 255, green: 0.3 + rand, blue: 0.5, alpha: 1)
        let downColor = UIColor(red: rand / 255, green: 0.3, blue: 0.5 + rand, alpha: 1)
        return (upColor, downColor)
    }
}
