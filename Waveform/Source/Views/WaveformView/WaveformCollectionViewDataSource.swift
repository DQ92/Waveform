
import UIKit


class WaveformCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    private let configurator: WaveformCollectionViewCellConfigurator!
    var values = [[WaveformModel]]()



    init(configurator: WaveformCollectionViewCellConfigurator) {
        self.configurator = configurator
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return values.count
    }

    func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WaveformConfiguration.collectionViewItemReuseIdentifier, for: indexPath) as! WaveformCollectionViewCell
        cell.configurator = configurator

        let second = indexPath.section
        let valuesInSecond: [WaveformModel] = values[second]

        for x in 0..<valuesInSecond.count {
            updateCell(cell, CGFloat(x), valuesInSecond[x])
        }
        return cell
    }

    private func updateCell(_ cell: WaveformCollectionViewCell, _ sampleIndex: CGFloat, _ model: WaveformModel) {
//        let sampleValue = model.value
//        let color = WaveformColor.color(model: model)
//        cell.setup(sampleValue: sampleValue, color: color, sampleIndex: sampleIndex)
    }
}

