
import UIKit

struct WaveformModel {
    let value: CGFloat
    let mode: RecordingMode
    let timeStamp: TimeInterval

    init(value: CGFloat, mode: RecordingMode, timeStamp: TimeInterval) {
        self.value = value
        self.mode = mode
        self.timeStamp = timeStamp
    }
}
