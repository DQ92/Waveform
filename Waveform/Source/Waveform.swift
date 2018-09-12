
import UIKit


class Waveform {

    private let collectionViewDataSource = WaveformCollectionViewDataSource(configurator: RecorderWaveformCollectionViewCellConfigurator())
    private let collectionViewFlowLayout = WaveformCollectionViewDelegateFlowLayout (configurator: RecorderWaveformCollectionViewCellConfigurator())

    private var values = [[WaveformModel]]()

    
}
