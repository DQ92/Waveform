
import Foundation
import UIKit

class WaveformColor {
    static func color(model: WaveformModel) -> UIColor {
        let part: CGFloat = CGFloat(model.numberOfRecord)
        let rand: CGFloat = part * 25
        let color = UIColor(red: rand / 255, green: 0.3 + rand, blue: 0.5, alpha: 1)
        return color
    }
}
