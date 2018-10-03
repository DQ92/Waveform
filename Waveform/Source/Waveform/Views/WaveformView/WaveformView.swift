//
//  WaveformView.swift
//  Waveform
//
//  Created by Robert Mietelski on 26.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

protocol WaveformViewDataSource: class {
    func numberOfTimeInterval(in waveformView: WaveformView) -> Int
    func standardTimeIntervalWidth(in waveformView: WaveformView) -> CGFloat
    
    func waveformView(_ waveformView: WaveformView, samplesAtTimeIntervalIndex index: Int) -> [Sample]
    func waveformView(_ waveformView: WaveformView, timeIntervalWidthAtIndex index: Int) -> CGFloat
}

protocol WaveformViewDelegate: class {
    func waveformView(_ waveformView: WaveformView, contentSizeDidChange contentSize: CGSize)
    func waveformView(_ waveformView: WaveformView, contentOffsetDidChange contentOffset: CGPoint)
}

class WaveformView: UIView {
    
    // MARK: - Public properties
    
    weak var dataSource: WaveformViewDataSource?
    weak var delegate: WaveformViewDelegate?
    
    var contentOffset: CGPoint {
        set {
            self.collectionView.bounds = CGRect(origin: newValue, size: self.collectionView.bounds.size)
        }
        get {
            return self.collectionView.contentOffset
        }
    }
    
    var contentInset: UIEdgeInsets {
        set {
            self.collectionView.contentInset = newValue
        }
        get {
            return self.collectionView.contentInset
        }
    }
    
    // MARK: - Private properties
    
    private lazy var coordinator: WaveformViewCoordinator = {
        let coordinator = WaveformViewCoordinator(cellIdentifier: "WaveformViewCellIdentifier", endlessScrollingEnabled: false)
        coordinator.dataSource = self
        coordinator.delegate = self
            
        return coordinator
    }()
    
    private var observers: [NSKeyValueObservation] = []
    
    // MARK: - Views
    
    private lazy var collectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumInteritemSpacing = 0.0
        collectionViewLayout.minimumLineSpacing = 0.0
        collectionViewLayout.sectionInset = .zero
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(WaveformCollectionViewCell.self, forCellWithReuseIdentifier: self.coordinator.cellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self.coordinator
        collectionView.delegate = self.coordinator
        collectionView.backgroundColor = .clear
        self.addSubview(collectionView)
        
        return collectionView
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupConstraints()
        self.setupObservers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupConstraints()
        self.setupObservers()
    }
    
    private func setupConstraints() {
        self.setupConstraint(attribute: .top, toItem: self.collectionView, attribute: .top, constant: -12.0)
        self.setupConstraint(attribute: .bottom, toItem: self.collectionView, attribute: .bottom, constant: 12.0)
        self.setupConstraint(attribute: .leading, toItem: self.collectionView, attribute: .leading)
        self.setupConstraint(attribute: .trailing, toItem: self.collectionView, attribute: .trailing)
    }
    
    private func setupObservers() {
        self.observers = [
            self.collectionView.observe(\.contentSize, options: [.new, .old]) { [weak self] collectionView, change in
                guard let caller = self, let currentContentSize = change.newValue else {
                    return
                }
                let previousContentSize = change.oldValue ?? currentContentSize
                
                if currentContentSize != previousContentSize {
                    caller.delegate?.waveformView(caller, contentSizeDidChange: currentContentSize)
                }
            }
        ]
    }
    
    // MARK: - Access methods
    
    func reloadData() {
        self.collectionView.reloadData()
    }
}

extension WaveformView: WaveformViewCoordinatorDataSource {
    func numberOfTimeInterval(in coordinator: WaveformViewCoordinator) -> Int {
        guard let result = self.dataSource?.numberOfTimeInterval(in: self) else {
            return 0
        }
        return result
    }
    
    func standardTimeIntervalWidth(in coordinator: WaveformViewCoordinator) -> CGFloat {
        guard let result = self.dataSource?.standardTimeIntervalWidth(in: self) else {
            return 0.0
        }
        return result
    }
    
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, samplesAtTimeIntervalIndex index: Int) -> [Sample] {
        guard let result = self.dataSource?.waveformView(self, samplesAtTimeIntervalIndex: index) else {
            return []
        }
        return result
    }
    
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, timeIntervalWidthAtIndex index: Int) -> CGFloat {
        guard let result = self.dataSource?.waveformView(self, timeIntervalWidthAtIndex: index) else {
            return 0.0
        }
        return result
    }
}

extension WaveformView: WaveformViewCoordinatorDelegate {
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, contentOffsetDidChange contentOffset: CGPoint) {
        self.delegate?.waveformView(self, contentOffsetDidChange: contentOffset)
    }
}
