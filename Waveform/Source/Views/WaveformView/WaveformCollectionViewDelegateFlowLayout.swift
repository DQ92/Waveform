
import UIKit


class WaveformCollectionViewDelegateFlowLayout: NSObject, UICollectionViewDelegateFlowLayout {

    private let configurator: WaveformCollectionViewCellConfigurator!


    init(configurator: WaveformCollectionViewCellConfigurator) {
        self.configurator = configurator
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: configurator.oneSecondWidth(), height: collectionView.bounds.size.height)
    }
}