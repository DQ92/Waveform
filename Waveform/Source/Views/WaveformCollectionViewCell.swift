
import Foundation
import UIKit

class WaveformCollectionViewCell: UICollectionViewCell {

    // MARK: - Private properties
    
    var layersList = [CAShapeLayer]()
    var numberOfLayers: Int! {
        didSet {
            layersList = [CAShapeLayer](repeating: CAShapeLayer(), count: numberOfLayers)
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
        let layerHeight = model.value //TODO liczyć skalę na podstawie wysokości celki i min/max wartości z model.value, pytanie czy RMS ma jakąś wartość max...
        let layerWidth: CGFloat = 1
        let layerY = (self.bounds.height - layerHeight) / 2
        let waveLayer = CAShapeLayer()
        waveLayer.frame = CGRect(x: sampleIndex, y: layerY, width: layerWidth, height: layerHeight)
        waveLayer.backgroundColor = WaveformColor.colors(model: model).0.cgColor
        layersList[Int(sampleIndex)].removeFromSuperlayer()
        self.contentView.layer.addSublayer(waveLayer)
        layersList[Int(sampleIndex)] = waveLayer
    }
}
