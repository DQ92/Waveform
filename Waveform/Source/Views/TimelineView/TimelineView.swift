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
            self.setNeedsReloadData()
        }
    }
    
    var intervalWidth: CGFloat = 100 {
        didSet {
            self.boundsVew.intervalWidth = intervalWidth
            self.setNeedsReloadData()
        }
    }
    
    var lineWidth: CGFloat = 1.0 {
        didSet {
            self.boundsVew.lineWidth = lineWidth
            self.setNeedsReloadData()
        }
    }
    
    var lineColor: UIColor = UIColor.gray {
        didSet {
            self.boundsVew.lineColor = lineColor
            self.setNeedsReloadData()
        }
    }
    
    var sublineHeight: CGFloat = 7.0 {
        didSet {
            self.boundsVew.sublineHeight = sublineHeight
            self.setNeedsReloadData()
        }
    }
    
    var numberOfSublines: Int = 3 {
        didSet {
            self.boundsVew.numberOfSublines = numberOfSublines
            self.setNeedsReloadData()
        }
    }
    
    // MARK: - Private attributes
    
    private static let collectionViewCellIdentifier = "CollectionViewCellIdentifier"
    
    private lazy var collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumInteritemSpacing = 0.0
        collectionViewLayout.minimumLineSpacing = 0.0
        
        return collectionViewLayout
    }()
    
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        
        return formatter
    }()
    
    private var numberOfItems: Int = 20
    private var reloadTimer: Timer?
    
    // MARK: - Views
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewFlowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(IntervalCollectionViewCell.self, forCellWithReuseIdentifier: TimelineView.collectionViewCellIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        //collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
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

extension TimelineView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TimelineView.collectionViewCellIdentifier,
                                                            for: indexPath) as? IntervalCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let timeInterval = self.timeInterval * Double(indexPath.row)
        let date = Date(timeIntervalSince1970: timeInterval)
        
        cell.timeLabelInsets = UIEdgeInsets(top: 0.0, left: self.lineWidth + 4.0, bottom: self.sublineHeight + 2, right: self.lineWidth + 4)
        cell.timeLabel.font = UIFont.systemFont(ofSize: 10.5)
        cell.timeLabel.text = self.timeFormatter.string(from: date)
        
        return cell
    }
}

extension TimelineView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row > self.numberOfItems - 10 {
            let currentNumberOfItems = self.numberOfItems + 10
            let indexPaths = (self.numberOfItems...currentNumberOfItems - 1).map { IndexPath(row: $0, section: indexPath.section) }
            
            collectionView.performBatchUpdates({
                self.numberOfItems = currentNumberOfItems
                collectionView.insertItems(at: indexPaths)
            }, completion: { _ in
                collectionView.reloadData()
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.intervalWidth, height: collectionView.bounds.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}
