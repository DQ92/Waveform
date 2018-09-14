//
//  WaveformPlot.swift
//  Waveform
//
//  Created by Robert Mietelski on 07.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

class WaveformPlot: UIView {

    // MARK: - Views
    
    lazy var timelineView: TimelineView = {
        let timelineView = TimelineView(frame: .zero)
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(timelineView)
        
        return timelineView
    }()
    
    lazy var waveformView: WaveformView = {
        let waveformView = WaveformView(frame: .zero)
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(waveformView)
        
        return waveformView
    }()
    
    // MARK: - Private properties
    
    private var observers = [NSKeyValueObservation]()
    
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
        self.timelineView.setupConstraint(attribute: .leading, toItem: self, attribute: .leading)
        self.timelineView.setupConstraint(attribute: .trailing, toItem: self, attribute: .trailing)
        self.timelineView.setupConstraint(attribute: .top, toItem: self, attribute: .top)
        self.timelineView.setupConstraint(attribute: .height, constant: 20.0)
        
        self.waveformView.setupConstraint(attribute: .leading, toItem: self, attribute: .leading)
        self.waveformView.setupConstraint(attribute: .trailing, toItem: self, attribute: .trailing)
        self.waveformView.setupConstraint(attribute: .top, toItem: self.timelineView, attribute: .bottom)
        self.waveformView.setupConstraint(attribute: .bottom, toItem: self, attribute: .bottom)
    }
    
    private func setupObservers() {
        self.observers = [
            self.waveformView.observe(\WaveformView.contentOffset, options: [.initial, .new]) { [weak self] waveformView, change in
                self?.timelineView.contentOffset = change.newValue ?? CGPoint.zero
            },
            self.waveformView.observe(\WaveformView.elementsPerSecond, options: [.initial, .new]) { [weak self] waveformView, change in
                self?.timelineView.intervalWidth = CGFloat(change.newValue ?? 0)
            }
        ]
    }
}
