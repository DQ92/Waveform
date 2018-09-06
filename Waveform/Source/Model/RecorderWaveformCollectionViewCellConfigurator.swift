
import UIKit


protocol WaveformCollectionViewCellConfigurator {
    func emptyListOfLayersPerOneSecond() -> [CAShapeLayer]
    func oneLayerWidth() -> CGFloat
    func oneSecondWidth() -> CGFloat
}

class RecorderWaveformCollectionViewCellConfigurator: WaveformCollectionViewCellConfigurator {
    private let numberOfLayersInCell = WaveformConfiguration.microphoneSamplePerSecond
    
    func emptyListOfLayersPerOneSecond() -> [CAShapeLayer] {
        return [CAShapeLayer](repeating: CAShapeLayer(), count: numberOfLayersInCell)
    }
    
    func oneLayerWidth() -> CGFloat {
        let oneSecondWidth = UIScreen.main.bounds.width / CGFloat(WaveformConfiguration.amountOfSecondsDisplayingOnScreen)
        return oneSecondWidth / CGFloat(numberOfLayersInCell)
    }

    func oneSecondWidth() -> CGFloat {
        return UIScreen.main.bounds.width / CGFloat(WaveformConfiguration.amountOfSecondsDisplayingOnScreen)
    }
}
