//
//  WaveformViewCoordinator.swift
//  Waveform
//
//  Created by Robert Mietelski on 18.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

protocol WaveformViewCoordinatorDataSource: class {
    func numberOfTimeInterval(in coordinator: WaveformViewCoordinator) -> Int
    func standardTimeIntervalWidth(in coordinator: WaveformViewCoordinator) -> CGFloat

    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, samplesAtTimeIntervalIndex index: Int) -> [Sample]
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, timeIntervalWidthAtIndex index: Int) -> CGFloat
}
protocol WaveformViewCoordinatorDelegate: class {
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, contentOffsetDidChange contentOffset: CGPoint)
}

class WaveformViewCoordinator: EndlessScrollingCoordinator {

    // MARK: - Public properties
    
    weak var dataSource: WaveformViewCoordinatorDataSource?
    weak var delegate: WaveformViewCoordinatorDelegate?
    
    // MARK: - Private properties
    
    private var contentSize: CGSize = .zero
}

extension WaveformViewCoordinator: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.endlessScrollingEnabled {
            return self.numberOfItems
        } else if let dataSource = self.dataSource {
            return dataSource.numberOfTimeInterval(in: self)
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier, for: indexPath) as! WaveformCollectionViewCell
        var samples: [Sample] = []
        
        if let dataSource = self.dataSource {
            let numberOfRows = dataSource.numberOfTimeInterval(in: self)
            
            if indexPath.row < numberOfRows {
                samples = dataSource.waveformViewCoordinator(self, samplesAtTimeIntervalIndex: indexPath.row)
            }
        }
        cell.setupSamples(samples)
        
        return cell
    }
}

extension WaveformViewCoordinator: UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.contentSize == scrollView.contentSize {
            self.delegate?.waveformViewCoordinator(self, contentOffsetDidChange: scrollView.contentOffset)
        }
        self.contentSize = scrollView.contentSize
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let dataSource = self.dataSource {
            let width: CGFloat
            
            if self.endlessScrollingEnabled {
                width = dataSource.standardTimeIntervalWidth(in: self)
            } else {
                width = dataSource.waveformViewCoordinator(self, timeIntervalWidthAtIndex: indexPath.row)
            }
            return CGSize(width: width, height: collectionView.bounds.size.height)
        }
        return CGSize.zero
    }
}
