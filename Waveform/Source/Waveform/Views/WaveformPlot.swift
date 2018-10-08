//
//  WaveformPlot.swift
//  Waveform
//
//  Created by Robert Mietelski on 07.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class WaveformPlot: UIView, ScrollablePlot {

    // MARK: - Public properties
    
    weak var dataSource: WaveformPlotDataSource?
    weak var delegate: WaveformPlotDelegate?
    
    var contentOffset: CGPoint {
        set {
            self.timelineView.contentOffset = newValue
            self.waveformView.contentOffset = newValue
        }
        get {
            return waveformView.contentOffset
        }
    }
    
    var contentInset: UIEdgeInsets {
        set {
            self.timelineView.contentInset = newValue
            self.waveformView.contentInset = newValue
        }
        get {
            return self.waveformView.contentInset
        }
    }
    
    var currentPosition: CGFloat = 0.0 {
        didSet {
            self.contentOffset = CGPoint(x: currentPosition - self.contentInset.left, y: 0.0)
            self.delegate?.waveformPlot(self, currentPositionDidChange: currentPosition)
        }
    }
    
    var standardTimeIntervalWidth: CGFloat = 100.0 {
        didSet {
            self.timelineView.intervalWidth = standardTimeIntervalWidth
            self.waveformView.reloadData()
        }
    }
    
    var contentSize: CGSize {
        return self.waveformView.contentSize
    }

    // MARK: - Views
    
    private lazy var timelineView: TimelineView = {
        let timelineView = TimelineView(frame: .zero)
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        timelineView.backgroundColor = .clear
        self.addSubview(timelineView)
        
        return timelineView
    }()
    
    private lazy var waveformView: WaveformView = {
        let waveformView = WaveformView(frame: .zero)
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        waveformView.backgroundColor = .clear
        waveformView.dataSource = self
        waveformView.delegate = self
        self.addSubview(waveformView)
        
        return waveformView
    }()
    
    var timeIndicatorView: UIView? {
        willSet {
            timeIndicatorView?.removeFromSuperview()
        }
        didSet {
            if let view = timeIndicatorView {
                view.translatesAutoresizingMaskIntoConstraints = false
                self.waveformView.addSubview(view)
                
                self.setupConstraint(item: view, attribute: .top, toItem: self.waveformView, attribute: .top)
                self.setupConstraint(item: view, attribute: .bottom, toItem: self.waveformView, attribute: .bottom)
                self.setupConstraint(item: view, attribute: .centerX, toItem: self.waveformView, attribute: .centerX)
            }
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
        self.setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
        self.setupConstraints()
    }
    
    private func commonInit() {
        
    }
    
    private func setupConstraints() {
        self.setupConstraint(item: self.timelineView, attribute: .leading, toItem: self, attribute: .leading)
        self.setupConstraint(item: self.timelineView, attribute: .trailing, toItem: self, attribute: .trailing)
        self.setupConstraint(item: self.timelineView, attribute: .top, toItem: self, attribute: .top)
        self.setupConstraint(item: self.timelineView, attribute: .height, constant: 20.0)
        
        self.setupConstraint(item: self.waveformView, attribute: .leading, toItem: self, attribute: .leading)
        self.setupConstraint(item: self.waveformView, attribute: .trailing, toItem: self, attribute: .trailing)
        self.setupConstraint(item: self.waveformView, attribute: .top, toItem: self.timelineView, attribute: .bottom)
        self.setupConstraint(item: self.waveformView, attribute: .bottom, toItem: self, attribute: .bottom)
    }
    
    // MARK: - Access methods
    
    func reloadData() {
        self.timelineView.timeInterval = dataSource?.timeInterval(in: self) ?? 1.0
        self.waveformView.reloadData()
    }
}

extension WaveformPlot: WaveformViewDataSource {
    func numberOfTimeIntervals(in waveformView: WaveformView) -> Int {
        guard let result = self.dataSource?.numberOfTimeIntervals(in: self) else {
            return 0
        }
        return result
    }
    
    func standardTimeIntervalWidth(in waveformView: WaveformView) -> CGFloat {
        return self.standardTimeIntervalWidth
    }
    
    func waveformView(_ waveformView: WaveformView, samplesAtTimeIntervalIndex index: Int) -> [Sample] {
        guard let result = self.dataSource?.waveformPlot(self, samplesAtTimeIntervalIndex: index) else {
            return []
        }
        return result
    }
    
    func waveformView(_ waveformView: WaveformView, timeIntervalWidthAtIndex index: Int) -> CGFloat {
        guard let result = self.dataSource?.waveformPlot(self, timeIntervalWidthAtIndex: index) else {
            return 0.0
        }
        return result
    }
}

extension WaveformPlot: WaveformViewDelegate {
    func waveformView(_ waveformView: WaveformView, contentOffsetDidChange contentOffset: CGPoint) {
        self.currentPosition = contentOffset.x + waveformView.contentInset.left
        self.timelineView.contentOffset = contentOffset
        
        self.delegate?.waveformPlot(self, contentOffsetDidChange: contentOffset)
    }
    
    func waveformView(_ waveformView: WaveformView, contentSizeDidChange contentSize: CGSize) {
        self.delegate?.waveformPlot(self, contentSizeDidChange: contentSize)
    }
}
