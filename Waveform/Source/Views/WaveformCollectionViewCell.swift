
import Foundation
import UIKit

class WaveformCollectionViewCell: UICollectionViewCell {

    // MARK: - Private properties
    
    var upList = [CAShapeLayer]()
    var downList = [CAShapeLayer]()
    var numberOfLayers: Int! {
        didSet {
            upList = [CAShapeLayer](repeating: CAShapeLayer(), count: numberOfLayers)
            downList = [CAShapeLayer](repeating: CAShapeLayer(), count: numberOfLayers)
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
    
    
    
    func setup(model: WaveformModel, sampleIndex: CGFloat) { //TODO przerobić na uzywanie jednego layerka zamiast dodwać dwa, ale do tego trzeba znać wysokość celki, żeby wyznaczyć Y
        let upLayer = CAShapeLayer()
        let downLayer = CAShapeLayer()
        let layerY = CGFloat(self.bounds.size.height / 2)
        upLayer.frame = CGRect(x: sampleIndex, y: layerY, width: 1, height: -model.value)
        upLayer.backgroundColor = WaveformColor.colors(model: model).0.cgColor
        upLayer.lineWidth = 1
        upList[Int(sampleIndex)].removeFromSuperlayer()
        self.contentView.layer.addSublayer(upLayer)
        upList[Int(sampleIndex)] = upLayer
        
        downLayer.frame = CGRect(x: sampleIndex, y: layerY, width: 1, height: model.value)
        downLayer.backgroundColor = WaveformColor.colors(model: model).1.cgColor
        downLayer.lineWidth = 1
        downList[Int(sampleIndex)].removeFromSuperlayer()
        self.contentView.layer.addSublayer(downLayer)
        downList[Int(sampleIndex)] = downLayer
    }
}
