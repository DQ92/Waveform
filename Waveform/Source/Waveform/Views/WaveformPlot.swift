//
//  WaveformPlot.swift
//  Waveform
//
//  Created by Robert Mietelski on 07.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

protocol WaveformPlotDelegate: class {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval)
    func contentOffsetDidChange(_ contentOffset: CGPoint)
    func zoomLevelDidChange(_ zoomLevel: ZoomLevel)
}

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
        waveformView.delegate = self
        self.addSubview(waveformView)
        return waveformView
    }()

    // MARK: - Public properties

    weak var delegate: WaveformPlotDelegate?

    var recordingModeEnabled: Bool = false {
        didSet {
            self.isUserInteractionEnabled = !recordingModeEnabled
            self.waveformView.recordingModeEnabled = recordingModeEnabled
        }
    }
    var contentOffset: CGPoint {
        set {
            self.waveformView.contentOffset = newValue
        }
        get {
            return waveformView.contentOffset
        }
    }
    private var zoom: Zoom = Zoom()

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
        self.timelineView.contentOffset = self.waveformView.contentOffset
        self.timelineView.intervalWidth = CGFloat(self.waveformView.layersPerSecond)
        timelineView.backgroundColor = .clear
        waveformView.backgroundColor = .clear
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

    // MARK: - Access methods

    func reset() {
        self.waveformView.reset()
    }
}

// MARK: - Waveform delegate

extension WaveformPlot: WaveformViewDelegate {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval) {
        self.delegate?.currentTimeIntervalDidChange(timeInterval)
    }

    func contentOffsetDidChange(_ contentOffset: CGPoint) {
        self.timelineView.contentOffset = contentOffset
        self.delegate?.contentOffsetDidChange(contentOffset)
    }

    func secondWidthDidChange(_ secondWidth: CGFloat) {
        self.timelineView.intervalWidth = secondWidth
    }
}

// MARK: - Zoom

extension WaveformPlot {
    func zoomIn() {
        zoom.in()
        zoomLevelDidChange()
    }

    func zoomOut() {
        zoom.out()
        zoomLevelDidChange()
    }

    func resetZoom() {
        zoom.reset()
        zoomLevelDidChange()
    }

    private func zoomLevelDidChange() {
        waveformView.zoomLevelDidChange(with: zoom.level)
        timelineView.timeInterval = TimeInterval(zoom.level.samplesPerLayer)
        delegate?.zoomLevelDidChange(zoom.level)
    }

    func currentZoomPercent() -> String {
        return zoom.level.percent
    }

    func changeSamplesPerPoint(_ samplesPerPoint: CGFloat) {
        zoom.changeSamplesPerPoint(samplesPerPoint)
    }
}