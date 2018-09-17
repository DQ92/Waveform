//
//  WaveformWithIllustrationsPlot.swift
//  Waveform
//
//  Created by Piotr Olech on 17/09/2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

protocol WaveformWithIllustrationsPlotDelegate: class {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval)
    //func contentOffsetDidChange(_ contentOffset: CGPoint)
}

class WaveformWithIllustrationsPlot: UIView {
    
    // MARK: - Views
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        return scrollView
    }()
    
    lazy var waveformPlot: WaveformPlot = {
        let waveformPlotView = WaveformPlot(frame: .zero)
        waveformPlotView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveformPlotView)
        
        return waveformPlotView
    }()
    
    // MARK: - Public properties
    
    weak var delegate: WaveformWithIllustrationsPlotDelegate?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        scrollView.setupConstraint(attribute: .leading, toItem: self, attribute: .leading)
        scrollView.setupConstraint(attribute: .trailing, toItem: self, attribute: .trailing)
        scrollView.setupConstraint(attribute: .top, toItem: self, attribute: .top)
        scrollView.setupConstraint(attribute: .bottom, toItem: self, attribute: .bottom)
        
        waveformPlot.setupConstraint(attribute: .leading, toItem: self, attribute: .leading)
        waveformPlot.setupConstraint(attribute: .trailing, toItem: self, attribute: .trailing)
        waveformPlot.setupConstraint(attribute: .bottom, toItem: self, attribute: .bottom)
        waveformPlot.setupConstraint(attribute: .height, toItem: self, attribute: .height, multiplier: 0.7, constant: 0)
    }
}
