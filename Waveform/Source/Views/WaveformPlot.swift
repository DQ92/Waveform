//
//  WaveformPlot.swift
//  Waveform
//
//  Created by Robert Mietelski on 07.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

protocol WaveformPlotDelegate: class {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval)
    func contentOffsetDidChange(_ contentOffset: CGPoint)
}

class WaveformPlot: UIView {

    // MARK: - Views

    lazy var timelineView: TimelineView = {
        let timelineView = TimelineView(frame: .zero)
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        timelineView.coordinator = TimelineViewCoordinator(cellIdentifier: WaveformPlot.timelineViewCellIdentifier)
        self.addSubview(timelineView)
        
        return timelineView
    }()
    
    lazy var waveformView: WaveformView = {
        let waveformViewCoordinator = WaveformViewCoordinator(cellIdentifier: WaveformPlot.waveformViewCellIdentifier,
                                                              endlessScrollingEnabled: false)
        waveformViewCoordinator.dataSource = self
        waveformViewCoordinator.delegate = self
        
        let waveformView = WaveformView(frame: .zero)
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        waveformView.coordinator = waveformViewCoordinator
        waveformView.delegate = self
        self.addSubview(waveformView)
        
        return waveformView
    }()
    
    // MARK: - Public properties
    
    private(set) var currentTimeInterval: TimeInterval = 0.0
    private(set) var sampleIndex: Int = 0
    
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

    // MARK: - Private properties
    
    private static let timelineViewCellIdentifier = "TimelineViewCellIdentifier"
    private static let waveformViewCellIdentifier = "WaveformViewCellIdentifier"
    
    private var configurator = RecorderWaveformCollectionViewCellConfigurator()
    private var values: [WaveformModel] = []
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
        self.timelineView.intervalWidth = self.configurator.intervalWidth
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
    
    func setCurrentValue(_ value: Float, for timeInterval: TimeInterval, mode: RecordingMode) {
        let currentRow = self.sampleIndex / self.configurator.layersPerSecond
        let offset = CGFloat(self.sampleIndex) + 1.0 * CGFloat(self.zoom.level.samplesPerLayer)
        let indexPath = IndexPath(row: currentRow, section: 0)
        let model = WaveformModel(value: CGFloat(value), mode: mode, timeStamp: timeInterval)

        if self.coordinator.shouldLoadMoreItems(forIndexPath: indexPath) {
            self.values.append(model)
            self.coordinator.appendItems(atSection: indexPath.section,
                                         collectionView: self.waveformView.collectionView) { [weak self] in
                                            self?.updateLeadingLine(x: offset)
            }
        } else {
            if self.sampleIndex == self.values.count {
                self.values.append(model)
            } else {
                self.values[self.sampleIndex] = model
            }
//            self.collectionView.reloadItems(at: [indexPath])
            self.waveformView.reloadData()
            self.waveformView.updateLeadingLine(x: offset)
        }
    }
    
    func load(values: [WaveformModel]) {
        self.values = values
        self.collectionView.reloadData()
        updateLeadingLine(x: self.collectionView.bounds.size.width / 2)
        self.collectionView.contentInset = self.calculateContentInset()
        self.collectionView.contentOffset = CGPoint(x: -leadingLine.position.x, y: 0)
    }


    func reloadData() {
        self.waveformView.reloadData()
        
    }

    func reset() {
        self.values = []
        self.waveformView.reset()
    }
}

// MARK: - Waveform view coordinator dataSource

extension WaveformPlot: WaveformViewCoordinatorDataSource {
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, numberOfItemsInSection section: Int) -> Int {
        let numberOfLayers = Int(ceil(CGFloat(self.values.count) / CGFloat(self.zoom.level.samplesPerLayer)))
        return Int(ceil(CGFloat(numberOfLayers) / CGFloat(self.configurator.layersPerSecond)))
    }
    
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, samplesAtIndexPath indexPath: IndexPath) -> [Sample] {
        let samplesPerSecond = self.configurator.layersPerSecond * self.zoom.level.samplesPerLayer
        let startIndex = indexPath.row * samplesPerSecond
        let endIndex = min(startIndex + samplesPerSecond, self.values.count) - 1
        
        let subarray = Array(self.values[startIndex...endIndex])
        let range = 0..<Int(ceil(CGFloat(subarray.count) / CGFloat(self.zoom.level.samplesPerLayer)))
        var samples: [Sample] = []
        
        for index in range {
            let startIndex = index * self.zoom.level.samplesPerLayer
            let endIndex = min(startIndex + self.zoom.level.samplesPerLayer, subarray.count) - 1
            let range = startIndex...endIndex
            
            let models = subarray[range]
            let sum = models.map { $0.value }.reduce(0.0, +)
            let average = sum / CGFloat(range.count)
            
            samples.append(Sample(value: average,
                                  color: WaveformColor.color(for: models.last!.mode),
                                  width: self.configurator.sampleLayerWidth))
            
        }
        return samples
    }
    
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, customItemWidthAtIndexPath indexPath: IndexPath) -> CGFloat {
        let samplesPerSecond = self.configurator.layersPerSecond * self.zoom.level.samplesPerLayer
        let startIndex = indexPath.row * samplesPerSecond
        let numberOfLayer = Int(ceil(CGFloat(self.values.count - startIndex) / CGFloat(self.zoom.level.samplesPerLayer)))
        
        return CGFloat(min(numberOfLayer, self.configurator.layersPerSecond)) * self.configurator.sampleLayerWidth
    }
    
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, standardItemWidthAtIndexPath indexPath: IndexPath) -> CGFloat {
        return self.configurator.intervalWidth
    }
}

// MARK: - WaveformCoordinator delegate

extension WaveformPlot: WaveformViewCoordinatorDelegate {
    func waveformViewCoordinator(_ coordinator: WaveformViewCoordinator, contentOffsetDidChange contentOffset: CGPoint) {
//        let currentX = max(round(contentOffset.x + caller.leadingLine.position.x), 0.0)
//        caller.leadingLineTimeUpdater.changeTime(withX: currentX, and: caller.zoomLevel.samplesPerLayer)
//        caller.contentOffset = contentOffset
//        caller.delegate?.contentOffsetDidChange(contentOffset)
    }
}

// MARK: - Waveform delegate

extension WaveformPlot: WaveformViewDelegate {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval) {
        let value = Double(self.configurator.layersPerSecond) * timeInterval
        self.sampleIndex = Int(round(value))
        self.currentTimeInterval = timeInterval
        self.delegate?.currentTimeIntervalDidChange(timeInterval)
    }
    
    func contentOffsetDidChange(_ contentOffset: CGPoint) {
        self.timelineView.contentOffset = contentOffset
        self.delegate?.contentOffsetDidChange(contentOffset)
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
    }

    func currentZoomPercent() -> String {
        return zoom.level.percent
    }

    func changeSamplesPerPoint(_ samplesPerPoint: CGFloat) {
        zoom.changeSamplesPerPoint(samplesPerPoint)
    }
}
