//
//  EndlessScrollingCoordinator.swift
//  Waveform
//
//  Created by Robert Mietelski on 21.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class EndlessScrollingCoordinator: NSObject {
    
    // MARK: - Public properties
    
    var cellIdentifier: String
    var endlessScrollingEnabled: Bool
    var numberOfItems: Int
    var bufferSize: Int
    
    // MARK: - Initialization
    
    init(cellIdentifier: String, endlessScrollingEnabled: Bool = true, numberOfItems: Int = 20, bufferSize: Int = 10) {
        self.cellIdentifier = cellIdentifier
        self.endlessScrollingEnabled = endlessScrollingEnabled
        self.numberOfItems = numberOfItems
        self.bufferSize = bufferSize
        
        super.init()
    }
    
    // MARK: - Access methods
    
    func shouldLoadMoreItems(forIndexPath indexPath: IndexPath) -> Bool {
        return self.endlessScrollingEnabled && indexPath.row > self.numberOfItems - self.bufferSize
    }
    
    func appendItems(atSection section: Int, collectionView: UICollectionView, completion: (() -> Void)? = nil) {
        let currentNumberOfItems = self.numberOfItems + self.bufferSize
        let indexPaths = (self.numberOfItems...currentNumberOfItems - 1).map { IndexPath(row: $0, section: section) }
        
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates({
                self.numberOfItems = currentNumberOfItems
                collectionView.insertItems(at: indexPaths)
            }, completion: { _ in
                completion?()
            })
        }
    }
}
