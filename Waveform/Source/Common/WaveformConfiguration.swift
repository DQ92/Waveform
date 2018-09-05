
import Foundation
import UIKit

class WaveformConfiguration {
    #if !(TARGET_IPHONE_SIMULATOR)
    static let microphoneSamplePerSecond = 86
    
    #else
    static let microphoneSamplePerSecond = 44
    
    #endif
    
    static let amountOfSecondsDisplayingOnScreen = 6
}
