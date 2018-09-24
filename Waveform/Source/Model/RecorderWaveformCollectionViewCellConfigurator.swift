
import UIKit

protocol WaveformCollectionViewCellConfigurator {
    var layersPerSecond: Int { get }
    var sampleLayerWidth: CGFloat { get }
}

extension WaveformCollectionViewCellConfigurator {
    var intervalWidth: CGFloat {
        return CGFloat(self.layersPerSecond) * self.sampleLayerWidth
    }
}

class RecorderWaveformCollectionViewCellConfigurator: WaveformCollectionViewCellConfigurator {
    let layersPerSecond: Int = WaveformConfiguration.microphoneSamplePerSecond
    var sampleLayerWidth: CGFloat = 1.0
}
