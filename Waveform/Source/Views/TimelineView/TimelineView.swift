//
//  TimelineView.swift
//  Waveform
//
//  Created by Robert Mietelski on 06.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//
import UIKit

class TimelineView: UIView {
    
    // MARK: - Public attributes
    
    var timeInterval: TimeInterval = 1.0 {
        didSet {
            self.coordinator.timeInterval = timeInterval
            self.setNeedsReloadData()
        }
    }
    
    var intervalWidth: CGFloat = 100 {
        didSet {
            self.boundsVew.intervalWidth = intervalWidth
            self.coordinator.intervalWidth = intervalWidth
            self.setNeedsReloadData()
        }
    }
    
    var lineWidth: CGFloat = 1.0 {
        didSet {
            self.boundsVew.lineWidth = lineWidth
            self.coordinator.lineWidth = lineWidth
            self.setNeedsReloadData()
        }
    }
    
    var lineColor: UIColor = UIColor.gray {
        didSet {
            self.boundsVew.lineColor = lineColor
            self.coordinator.lineColor = lineColor
            self.setNeedsReloadData()
        }
    }
    
    var sublineHeight: CGFloat = 7.0 {
        didSet {
            self.boundsVew.sublineHeight = sublineHeight
            self.coordinator.sublineHeight = sublineHeight
            self.setNeedsReloadData()
        }
    }
    
    var numberOfSublines: Int = 3 {
        didSet {
            self.boundsVew.numberOfSublines = numberOfSublines
            self.coordinator.numberOfSublines = numberOfSublines
            self.setNeedsReloadData()
        }
    }
    
    var contentOffset: CGPoint = .zero {
        didSet {
            self.collectionView.contentOffset = contentOffset
        }
    }
    
    // MARK: - Private attributes
    
    private static let collectionViewCellIdentifier = "CollectionViewCellIdentifier"
    private var reloadTimer: Timer?
    
    private lazy var coordinator: TimelineCoordinator = {
        return TimelineCoordinator(cellIdentifier: TimelineView.collectionViewCellIdentifier)
    }()
    
    // MARK: - Views
    
    private lazy var collectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumInteritemSpacing = 0.0
        collectionViewLayout.minimumLineSpacing = 0.0
        collectionViewLayout.sectionInset = .zero
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(IntervalCollectionViewCell.self, forCellWithReuseIdentifier: TimelineView.collectionViewCellIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self.coordinator
        collectionView.delegate = self.coordinator
        collectionView.backgroundColor = .clear
        self.addSubview(collectionView)
        
        return collectionView
    }()
    
    private lazy var boundsVew: IntervalView = {
        let view = IntervalView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.transform = CGAffineTransform(scaleX: -1, y: 1);
        self.collectionView.addSubview(view)
        
        return view
    }()

    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupConstraints()
    }
    
    private func setupConstraints() {
        self.setupConstraint(attribute: .top, toItem: self.collectionView, attribute: .top)
        self.setupConstraint(attribute: .bottom, toItem: self.collectionView, attribute: .bottom)
        self.setupConstraint(attribute: .leading, toItem: self.collectionView, attribute: .leading)
        self.setupConstraint(attribute: .trailing, toItem: self.collectionView, attribute: .trailing)
        
        self.boundsVew.setupConstraint(attribute: .width, toItem: self.collectionView, attribute: .width)
        self.boundsVew.setupConstraint(attribute: .height, toItem: self.collectionView, attribute: .height)
        self.boundsVew.setupConstraint(attribute: .centerY, toItem: self.collectionView, attribute: .centerY)
        self.boundsVew.setupConstraint(attribute: .trailing, toItem: self.collectionView, attribute: .leading)
    }
    
    // MARK: - Access methods
    
    @objc func reloadData() {
        self.collectionView.reloadData()
    }
    
    // MARK: - Mechanism of data reloading
    
    private func setNeedsReloadData() {
        self.stopTimer()
        self.startTimer()
    }
    
    private func reloadDataIfNeeded() {
        if self.reloadTimer != nil {
            self.stopTimer()
            self.reloadData()
        }
    }
    
    private func startTimer() {
        if self.reloadTimer == nil {
            self.reloadTimer = Timer.scheduledTimer(timeInterval: 0.001,
                                                    target: self,
                                                    selector: #selector(reloadData),
                                                    userInfo: nil,
                                                    repeats: false)
        }
    }
    
    private func stopTimer() {
        if let timer = self.reloadTimer {
            timer.invalidate()
        }
        self.reloadTimer = nil
    }
}
