//
//  WaveformCoordinator.swift
//  Waveform
//
//  Created by Robert Mietelski on 18.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

protocol WaveformViewCoordinatorDataSource: class {
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, numberOfItemsInSection section: Int) -> Int
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, samplesAtIndexPath indexPath: IndexPath) -> [Sample]
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, customItemWidthAtIndexPath indexPath: IndexPath) -> CGFloat
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, standardItemWidthAtIndexPath indexPath: IndexPath) -> CGFloat
}

protocol WaveformViewCoordinatorDelegate: class {
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, contentOffsetDidChange contentOffset: CGPoint)
}

class WaveformViewCoordinator: EndlessScrollingCoordinator {
    
    // MARK: - Public attributes
    
    weak var dataSource: WaveformViewCoordinatorDataSource?
    weak var delegate:WaveformViewCoordinatorDelegate?
}

extension WaveformViewCoordinator: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.endlessScrollingEnabled {
            return self.numberOfItems
        } else if let dataSource = self.dataSource {
            return dataSource.waveformViewCoordinator(self, numberOfItemsInSection: section)
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier, for: indexPath) as! WaveformCollectionViewCell
        var samples: [Sample] = []
        
        if let dataSource = self.dataSource {
            let numberOfRows = dataSource.waveformViewCoordinator(self, numberOfItemsInSection: indexPath.section)
            
            if indexPath.row < numberOfRows {
                samples = dataSource.waveformViewCoordinator(self, samplesAtIndexPath: indexPath)
            }
        }
        cell.setupSamples(samples)

        return cell
    }
}

extension WaveformViewCoordinator: UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.waveformViewCoordinator(self, contentOffsetDidChange: scrollView.contentOffset)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        if let dataSource = self.dataSource {
            let width: CGFloat
            
            if self.endlessScrollingEnabled {
                width = dataSource.waveformViewCoordinator(self, standardItemWidthAtIndexPath: indexPath)
            } else {
                width = dataSource.waveformViewCoordinator(self, customItemWidthAtIndexPath: indexPath)
            }
            return CGSize(width: width, height: collectionView.bounds.size.height)
        }
        return CGSize.zero
    }
}

