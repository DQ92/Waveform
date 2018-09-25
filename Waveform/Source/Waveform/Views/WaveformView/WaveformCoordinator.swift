//
//  WaveformCoordinator.swift
//  Waveform
//
//  Created by Robert Mietelski on 18.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class WaveformCoordinator: EndlessScrollingCoordinator {
    
    // MARK: - Public attributes
    
    let configurator = RecorderWaveformCollectionViewCellConfigurator()
    var contentOffsetDidChangeBlock: ((CGPoint) -> ())?
    var values: [WaveformModel] = []
    var samplePerLayer: Int = 1
    
    // MARK: - Access methods
    
    private func getSamples(indexPath: IndexPath) -> [Sample] {
        let samplesPerSecond = self.configurator.layersPerSecond * self.samplePerLayer
        let startIndex = indexPath.row * samplesPerSecond
        let endIndex = min(startIndex + samplesPerSecond, self.values.count) - 1
        
        let subarray = Array(self.values[startIndex...endIndex])
        let range = 0..<Int(ceil(CGFloat(subarray.count) / CGFloat(self.samplePerLayer)))
        var samples: [Sample] = []
        
        for index in range {
            let startIndex = index * self.samplePerLayer
            let endIndex = min(startIndex + self.samplePerLayer, subarray.count) - 1
            let range = startIndex...endIndex
            
            let models = subarray[range]
            let sum = models.map { $0.value }.reduce(0.0, +)
            let average = sum / CGFloat(range.count)
            
            samples.append(Sample(value: average,
                                  color: WaveformColor.color(for: models.last!.mode),
                                  width: self.configurator.sampleLayerWidth))
            
        }
        return samples
    }
    
    private func numberOfItemsInSection(_ section: Int) -> Int {
        let numberOfLayers = Int(ceil(CGFloat(self.values.count) / CGFloat(self.samplePerLayer)))
        return Int(ceil(CGFloat(numberOfLayers) / CGFloat(self.configurator.layersPerSecond)))
    }
}

extension WaveformCoordinator: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.endlessScrollingEnabled {
            return self.numberOfItems
        }
        return self.numberOfItemsInSection(section)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier, for: indexPath) as! WaveformCollectionViewCell
        let numberOfItems = self.numberOfItemsInSection(indexPath.section)
        var samples: [Sample] = []
        
        if indexPath.row < numberOfItems {
            samples = self.getSamples(indexPath: indexPath)
        }
        cell.setupSamples(samples)
        
        return cell
    }
}

extension WaveformCoordinator: UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.contentOffsetDidChangeBlock?(scrollView.contentOffset)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let standardWidth = CGFloat(self.configurator.layersPerSecond) * self.configurator.sampleLayerWidth
        
        if self.endlessScrollingEnabled {
            return CGSize(width: standardWidth, height: collectionView.bounds.size.height)
        }
        
        let samplesPerSecond = self.configurator.layersPerSecond * self.samplePerLayer
        let startIndex = indexPath.row * samplesPerSecond
        let numberOfLayer = Int(ceil(CGFloat(self.values.count - startIndex) / CGFloat(self.samplePerLayer)))
        let customWidth = CGFloat(min(numberOfLayer, self.configurator.layersPerSecond)) * self.configurator.sampleLayerWidth
        
        return CGSize(width: customWidth, height: collectionView.bounds.size.height)
    }

}

