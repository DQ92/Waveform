
import Foundation
import UIKit

class WaveformColor {
    static func color(model: WaveformModel) -> UIColor {
        var part: CGFloat
        switch model.recordType {
        case .first:
            part = 0
        case .ovveride(let turn):
            part = CGFloat(turn)
        default:
           Assert.checkRepresentation(true, "Recording type not implemented")
        }

        let rand: CGFloat = part * 25
        let color = UIColor(red: rand / 255, green: 0.3 + rand, blue: 0.5, alpha: 1)
        return color
    }
}
