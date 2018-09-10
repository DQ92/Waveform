
import Foundation
import UIKit

enum RecordType {
    case first
    case override(turn: Int)
}

struct WaveformModel {
    let value: CGFloat
    let recordType: RecordType
    let timeStamp: TimeInterval

    init(value: CGFloat, recordType: RecordType, timeStamp: TimeInterval) {
        self.value = value
        self.recordType = recordType
        self.timeStamp = timeStamp
    }
}
