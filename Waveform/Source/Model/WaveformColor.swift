
import Foundation
import UIKit

class WaveformColor {
    static func color(model: WaveformModel) -> UIColor {
        var part: CGFloat
        switch model.mode {
        case .normal:
            part = 0
        case .override(let turn):
            part = CGFloat(turn)
        }

        let rand: CGFloat = part * 25
        let color = UIColor(red: rand / 255, green: 0.3 + rand, blue: 0.5, alpha: 1)
        return color
    }
}
