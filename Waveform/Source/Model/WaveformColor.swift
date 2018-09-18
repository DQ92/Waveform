
import Foundation
import UIKit

class WaveformColor {
    static func color(for mode: RecordingMode) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0.5
        switch mode {
        case .normal:
            break
        case .override(let turn):
            red = CGFloat(turn) * 40.0 / 255.0
            green = 1
        }

        let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
        return color
    }
}
