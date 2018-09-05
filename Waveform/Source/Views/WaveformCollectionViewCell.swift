
import Foundation
import UIKit

class WaveformCollectionViewCell: UICollectionViewCell {

    // MARK: - Private properties
    
    private var layersList = [CAShapeLayer]()
    var configurator: WaveformCollectionViewCellConfigurator! {
        didSet {
            layersList = configurator.emptyListOfLayersPerOneSecond()
        }
    }
    
    
    // MARK: - Initialization

    override func prepareForReuse() {
        super.prepareForReuse()
        
        for sublayer in contentView.layer.sublayers ?? [] {
            sublayer.removeFromSuperlayer()
        }
        contentView.backgroundColor = nil
    }
    
    func setup(model: WaveformModel, sampleIndex: CGFloat) {
        Assert.checkRep(configurator == nil, "Set configurator for waveformCell!")
        
        let layerWidth = configurator.oneLayerWidth()
        var layerHeight: CGFloat = 1
        //TODO przeliczyć wysokość na podstawie wysokości celki i min/max wartości z model.value, pytanie czy RMS ma jakąś wartość max...
        if(model.value > 1) {
            layerHeight = model.value
        }
        let layerY = (self.bounds.height - layerHeight) / 2
        let waveLayer = CAShapeLayer()
        waveLayer.frame = CGRect(x: sampleIndex, y: layerY, width: layerWidth, height: layerHeight)
        waveLayer.backgroundColor = WaveformColor.colors(model: model).0.cgColor
        layersList[Int(sampleIndex)].removeFromSuperlayer()
        self.contentView.layer.addSublayer(waveLayer)
        layersList[Int(sampleIndex)] = waveLayer
    }
}






