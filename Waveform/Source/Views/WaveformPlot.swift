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
        self.waveformView.scrollDidChangeBlock = { [weak self] contentOffset in
            self?.timelineView.contentOffset = contentOffset
        }
        self.timelineView.intervalWidth = CGFloat(self.waveformView.elementsPerSecond)
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
}
