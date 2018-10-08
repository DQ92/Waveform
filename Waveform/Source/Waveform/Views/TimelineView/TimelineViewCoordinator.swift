//
//  TimelineViewCoordinator.swift
//  Waveform
//
//  Created by Robert Mietelski on 18.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class TimelineViewCoordinator: EndlessScrollingCoordinator {
    
    // MARK: - Public attributes
    
    var timeInterval: TimeInterval = 1.0
    var intervalWidth: CGFloat = 100
    var lineColor: UIColor = UIColor.gray
    var numberOfSublines: Int = 3
    
    var lineWidth: CGFloat = 1.0 {
        didSet {
            self.timeLabelInsets.left = lineWidth + 4
            self.timeLabelInsets.right = lineWidth + 4
        }
    }
    
    var sublineHeight: CGFloat = 7.0 {
        didSet {
            self.timeLabelInsets.bottom = lineWidth + 2
        }
    }
    
    // MARK: - Private attributes
    
    private var timeLabelInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 5.0, 10.0, 5.0)
    
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        
        return formatter
    }()
}

extension TimelineViewCoordinator: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier,
                                                            for: indexPath) as? IntervalCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let timeInterval = self.timeInterval * Double(indexPath.row)
        let date = Date(timeIntervalSince1970: timeInterval)
        
        cell.timeLabelInsets = self.timeLabelInsets
        cell.timeLabel.font = UIFont.systemFont(ofSize: 10.5)
        cell.timeLabel.text = self.timeFormatter.string(from: date)
        
        cell.intervalView.intervalWidth = self.intervalWidth
        cell.intervalView.lineWidth = self.lineWidth
        cell.intervalView.lineColor = self.lineColor
        cell.intervalView.sublineHeight = self.sublineHeight
        cell.intervalView.numberOfSublines = self.numberOfSublines
        
        return cell
    }
}

extension TimelineViewCoordinator: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if self.shouldLoadMoreItems(forIndexPath: indexPath) {
            self.appendItems(atSection: indexPath.section,
                             collectionView: collectionView) { [weak collectionView] in
                                collectionView?.reloadData()
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.intervalWidth, height: collectionView.bounds.size.height)
    }
}
