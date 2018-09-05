
import Foundation
import UIKit

struct WaveformModel {
    let value: CGFloat
    let numberOfRecord: Int
    let timeStamp: TimeInterval

    init(value: CGFloat, numberOfRecord: Int, timeStamp: TimeInterval) {
        self.value = value
        self.numberOfRecord = numberOfRecord
        self.timeStamp = timeStamp
    }
}
