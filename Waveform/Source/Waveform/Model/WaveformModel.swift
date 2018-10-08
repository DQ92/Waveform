
import UIKit

struct WaveformModel {
    let value: CGFloat
    let mode: AudioRecordingMode
    let timeStamp: TimeInterval

    init(value: CGFloat, mode: AudioRecordingMode, timeStamp: TimeInterval) {
        self.value = value
        self.mode = mode
        self.timeStamp = timeStamp
    }
}
