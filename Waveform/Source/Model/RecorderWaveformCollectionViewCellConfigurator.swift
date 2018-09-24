
import UIKit

protocol WaveformCollectionViewCellConfigurator {
    var layersPerSecond: Int { get }
    var sampleLayerWidth: CGFloat { get }
}

class RecorderWaveformCollectionViewCellConfigurator: WaveformCollectionViewCellConfigurator {
    let layersPerSecond: Int = WaveformConfiguration.microphoneSamplePerSecond
    var sampleLayerWidth: CGFloat = 1.0
}
