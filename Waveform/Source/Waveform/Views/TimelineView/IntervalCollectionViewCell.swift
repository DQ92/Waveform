//
//  IntervalCollectionViewCell.swift
//  Waveform
//
//  Created by Robert Mietelski on 06.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class IntervalCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Public attributes
    
    var timeLabelInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 5.0, 10.0, 5.0) {
        didSet {
            self.timeLabelLeadingConstraint.constant = timeLabelInsets.left
            self.timeLabelTrailingConstraint.constant = timeLabelInsets.right
            self.timeLabelTopConstraint.constant = timeLabelInsets.top
            self.timeLabelBottomConstraint.constant = timeLabelInsets.bottom
        }
    }
    
    // MARK: - Views
    
    lazy var timeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = NSTextAlignment.left
        self.intervalView.addSubview(label)
        
        return label
    }()
    
    lazy var intervalView: IntervalView = {
        let view = IntervalView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        self.contentView.addSubview(view)
        
        return view
    }()
    
    // MARK: - Private attributes
    
    private lazy var timeLabelLeadingConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint.build(item: self.timeLabel,
                                        attribute: .leading,
                                        toItem: self.intervalView,
                                        attribute: .leading,
                                        constant: self.timeLabelInsets.left)
    }()
    
    private lazy var timeLabelTrailingConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint.build(item: self.intervalView,
                                        attribute: .trailing,
                                        toItem: self.timeLabel,
                                        attribute: .trailing,
                                        constant: self.timeLabelInsets.right)
    }()
    
    private lazy var timeLabelTopConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint.build(item: self.timeLabel,
                                        attribute: .top,
                                        toItem: self.intervalView,
                                        attribute: .top,
                                        constant: self.timeLabelInsets.top)
    }()
    
    private lazy var timeLabelBottomConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint.build(item: self.intervalView,
                                        attribute: .bottom,
                                        toItem: self.timeLabel,
                                        attribute: .bottom,
                                        constant: self.timeLabelInsets.bottom)
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
        self.setupConstraint()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
        self.setupConstraint()
    }
    
    private func commonInit() {
        self.backgroundColor = UIColor.clear
    }
    
    private func setupConstraint() {
        self.timeLabelLeadingConstraint.isActive = true
        self.timeLabelTrailingConstraint.isActive = true
        self.timeLabelTopConstraint.isActive = true
        self.timeLabelBottomConstraint.isActive = true
        
        self.setupConstraint(item: self.intervalView, attribute: .leading, toItem: self, attribute: .leading)
        self.setupConstraint(item: self.intervalView, attribute: .trailing, toItem: self, attribute: .trailing)
        self.setupConstraint(item: self.intervalView, attribute: .top, toItem: self, attribute: .top)
        self.setupConstraint(item: self.intervalView, attribute: .bottom, toItem: self, attribute: .bottom)
    }
}
