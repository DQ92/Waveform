
import Foundation
import UIKit
import AVFoundation


class WaveformConfiguration {
    
    #if targetEnvironment(simulator)
    static let microphoneSamplePerSecond = 86
    #else
    static let microphoneSamplePerSecond = 43
    #endif
    
    static let amountOfSecondsDisplayingOnScreen = 6
    
    static func numberOfSamplesPerSecond(inViewWithWidth width: CGFloat) -> Int {
        return Int(width / CGFloat(amountOfSecondsDisplayingOnScreen))
    }
    
    static let preferredTimescale: CMTimeScale = 1000
    
    static let timeInterval: TimeInterval = (TimeInterval(Float(amountOfSecondsDisplayingOnScreen) / Float(UIScreen.main.bounds.width)))

    static let collectionViewItemReuseIdentifier = "collectionViewCell"
}
