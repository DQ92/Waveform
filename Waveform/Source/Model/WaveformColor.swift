
import Foundation
import UIKit

class WaveformColor {
    static func color(for mode: RecordingMode) -> UIColor {
        var red: CGFloat = 200/255
        var green: CGFloat = 200/255
        var blue: CGFloat = 200/255
        switch mode {
        case .normal:
            break
        case .override(let turn):
            red = 240 / 255
            green = 0
            blue = 0
        }

        let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
        return color
    }
}
