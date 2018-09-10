
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

    override init(frame: CGRect) {
        super.init(frame: frame)
     
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for sublayer in contentView.layer.sublayers ?? [] {
            sublayer.removeFromSuperlayer()
        }
        contentView.backgroundColor = nil
    }

    //TODO ta metoda bedzie to wyrzucenia
    func setup(model: WaveformModel, sampleIndex: CGFloat) {
        Assert.checkRepresentation(configurator == nil, "Set configurator for waveformCell!")
        
        let layerWidth = configurator.oneLayerWidth()
        var layerHeight: CGFloat = 1
        //TODO przeliczyć wysokość na podstawie wysokości celki i min/max wartości z model.value, pytanie czy RMS ma jakąś wartość max...
        if(model.value > 1) {
            layerHeight = model.value
        }
        let layerY = (self.bounds.height - layerHeight) / 2
        let waveLayer = CAShapeLayer()
        waveLayer.frame = CGRect(x: sampleIndex, y: layerY, width: layerWidth, height: layerHeight)
        waveLayer.backgroundColor = WaveformColor.color(model: model).cgColor
        
        let index = Int(sampleIndex)
        if(index >= layersList.count || index < 0) {
            Assert.checkRepresentation(true, "Wrong value of sampleIndex! : \(index)")
        } else {
            layersList[index].removeFromSuperlayer()
            self.contentView.layer.addSublayer(waveLayer)
            layersList[index] = waveLayer
        }
    }

    func setup(sampleValue: CGFloat, color: UIColor, sampleIndex: CGFloat) {
        Assert.checkRepresentation(configurator == nil, "Set configurator for waveformCell!")

        let layerWidth = configurator.oneLayerWidth()
        var layerHeight: CGFloat = 1
        //TODO przeliczyć wysokość na podstawie wysokości celki i min/max wartości z model.value, pytanie czy RMS ma jakąś wartość max...
        if(sampleValue > 1) {
            layerHeight = sampleValue
        }
        let layerY = (self.bounds.height - layerHeight) / 2
        let waveLayer = CAShapeLayer()
        waveLayer.frame = CGRect(x: sampleIndex, y: layerY, width: layerWidth, height: layerHeight)
        waveLayer.backgroundColor = color.cgColor

        let index = Int(sampleIndex)
        if(index > layersList.count || index < 0) {
            Assert.checkRepresentation(true, "Wrong value of sampleIndex! : \(index)")
        } else {
            layersList[index].removeFromSuperlayer()
            self.contentView.layer.addSublayer(waveLayer)
            layersList[index] = waveLayer
        }
    }
}






