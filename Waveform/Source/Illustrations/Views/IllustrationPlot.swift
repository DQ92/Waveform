//
//  IllustrationPlot.swift
//  Waveform
//
//  Created by Piotr Olech on 17/09/2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

protocol IllustrationPlotDataSource: class {
    func numberOfTimeInterval(in illustrationPlot: IllustrationPlot) -> Int
    
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, samplesAtTimeIntervalIndex index: Int) -> [Sample]
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, timeIntervalWidthAtIndex index: Int) -> CGFloat
}

protocol IllustrationPlotDelegate: class {
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, contentOffsetDidChange contentOffset: CGPoint)
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, currentPositionDidChange position: CGFloat)
}

class IllustrationPlot: UIView, ScrollablePlot {

    // MARK: - Public properties
    
    weak var dataSource: IllustrationPlotDataSource?
    weak var delegate: IllustrationPlotDataSource?
    
    var contentOffset: CGPoint {
        set {
            self.waveformPlot.contentOffset = newValue
        }
        get {
            return self.waveformPlot.contentOffset
        }
    }
    
    // MARK: - Views
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        self.addSubview(scrollView)
        
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.addSubview(view)
        
        return view
    }()
    
    private lazy var waveformPlot: WaveformPlot = {
        let waveformPlot = WaveformPlot(frame: .zero)
        waveformPlot.translatesAutoresizingMaskIntoConstraints = false
        waveformPlot.backgroundColor = UIColor.clear
        waveformPlot.dataSource = self
        waveformPlot.delegate = self
        self.addSubview(waveformPlot)
        
        return waveformPlot
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
        
    }
    
    private func setupConstraints() {
        self.waveformPlot.setupConstraint(attribute: .leading, toItem: self, attribute: .leading)
        self.waveformPlot.setupConstraint(attribute: .trailing, toItem: self, attribute: .trailing)
        self.waveformPlot.setupConstraint(attribute: .bottom, toItem: self, attribute: .bottom)
        self.waveformPlot.setupConstraint(attribute: .height, toItem: self, attribute: .height, multiplier: 0.7, constant: 0)
        
        self.scrollView.setupConstraint(attribute: .leading, toItem: self, attribute: .leading)
        self.scrollView.setupConstraint(attribute: .trailing, toItem: self, attribute: .trailing)
        self.scrollView.setupConstraint(attribute: .top, toItem: self, attribute: .top)
        self.scrollView.setupConstraint(attribute: .bottom, toItem: self, attribute: .bottom)
        
//        self.contentView.setupConstraint(attribute: .leading, toItem: scrollView, attribute: .leading, constant: -(illustrationMarkViewWidth))
//        self.contentView.setupConstraint(attribute: .trailing, toItem: scrollView, attribute: .trailing, constant: illustrationMarkViewWidth)
//        self.contentView.setupConstraint(attribute: .top, toItem: scrollView, attribute: .top)
//        self.contentView.setupConstraint(attribute: .bottom, toItem: scrollView, attribute: .bottom)
//        self.contentView.setupConstraint(attribute: .centerY, toItem: scrollView, attribute: .centerY)
    }
}

extension IllustrationPlot: UIScrollViewDelegate {
    
}

extension IllustrationPlot: WaveformPlotDataSource {
    func numberOfTimeInterval(in waveformPlot: WaveformPlot) -> Int {
        guard let result = self.dataSource?.numberOfTimeInterval(in: self) else {
            return 0
        }
        return result
    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, samplesAtTimeIntervalIndex index: Int) -> [Sample] {
        guard let result = self.dataSource?.illustrationPlot(self, samplesAtTimeIntervalIndex: index) else {
            return []
        }
        return result
    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, timeIntervalWidthAtIndex index: Int) -> CGFloat {
        guard let result = self.dataSource?.illustrationPlot(self, timeIntervalWidthAtIndex: index) else {
            return 0.0
        }
        return result
    }
}

extension IllustrationPlot: WaveformPlotDelegate {
    func waveformPlot(_ waveformPlot: WaveformPlot, contentOffsetDidChange contentOffset: CGPoint) {
        
    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, currentPositionDidChange position: CGFloat) {
        
    }
    
    
}

/*
protocol WaveformWithIllustrationsPlotDelegate: class {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval)
}

class WaveformWithIllustrationsPlot: UIView {
    
    // MARK: - Views
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        addSubview(scrollView)
        
        return scrollView
    }()
    
    lazy var scrollContentView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(view)
        
        return view
    }()
    
    lazy var waveformPlot: WaveformPlot = {
        let waveformPlotView = WaveformPlot(frame: .zero)
        waveformPlotView.delegate = self
        waveformPlotView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveformPlotView)
        
        return waveformPlotView
    }()
    
    // MARK: - Private properties
    
    private var illustrationMarkViewWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.08
    }
    private var illustrationMarkDataList: [IllustrationMarkModel] = []
    private var scrollContentViewWidthConstraint: NSLayoutConstraint = NSLayoutConstraint()
    private var currentZoomLevel: ZoomLevel = ZoomLevel(samplesPerLayer: 1, multiplier: 1.0)
    
    // MARK: - Private constants
    
    private let leftMarkViewVisibilityMargin = UIScreen.main.bounds.width * 0.5
    private let rightMarkViewVisibilityMargin = 2 * UIScreen.main.bounds.width
    
    // MARK: - Public properties
    
    weak var delegate: WaveformWithIllustrationsPlotDelegate?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupConstraints()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupConstraints()
        commonInit()
    }
    
    private func commonInit() {
        waveformPlot.isUserInteractionEnabled = false
        waveformPlot.backgroundColor = .clear
        waveformPlot.waveformView.backgroundColor = .clear
        waveformPlot.waveformView.isUserInteractionEnabled = false
        waveformPlot.timelineView.backgroundColor = .clear
    }
    
    private func setupConstraints() {
        scrollView.setupConstraint(attribute: .leading, toItem: self, attribute: .leading)
        scrollView.setupConstraint(attribute: .trailing, toItem: self, attribute: .trailing)
        scrollView.setupConstraint(attribute: .top, toItem: self, attribute: .top)
        scrollView.setupConstraint(attribute: .bottom, toItem: self, attribute: .bottom)
        
        scrollContentView.setupConstraint(attribute: .leading, toItem: scrollView, attribute: .leading, constant: -(illustrationMarkViewWidth))
        scrollContentView.setupConstraint(attribute: .trailing, toItem: scrollView, attribute: .trailing, constant: illustrationMarkViewWidth)
        scrollContentView.setupConstraint(attribute: .top, toItem: scrollView, attribute: .top)
        scrollContentView.setupConstraint(attribute: .bottom, toItem: scrollView, attribute: .bottom)
        scrollContentView.setupConstraint(attribute: .centerY, toItem: scrollView, attribute: .centerY)
        
        waveformPlot.setupConstraint(attribute: .leading, toItem: self, attribute: .leading)
        waveformPlot.setupConstraint(attribute: .trailing, toItem: self, attribute: .trailing)
        waveformPlot.setupConstraint(attribute: .bottom, toItem: self, attribute: .bottom)
        waveformPlot.setupConstraint(attribute: .height, toItem: self, attribute: .height, multiplier: 0.7, constant: 0)
    }
    
    func addIllustrationMark() {
        let halfOfScrollContentViewWidth = -(scrollContentView.bounds.width / 2)
        var centerXConstraintValue = halfOfScrollContentViewWidth + scrollView.contentInset.left + scrollView.contentOffset.x + illustrationMarkViewWidth
        centerXConstraintValue *= CGFloat(currentZoomLevel.samplesPerLayer)
        let currentTimeInterval = waveformPlot.waveformView.currentTimeInterval
        
        hideScrollContentViewSubviews()
        setAllIllustrationMarksInactive()
        let data = IllustrationMarkModel(timeInterval: currentTimeInterval,
                                         centerXConstraintValue: centerXConstraintValue,
                                         isActive: true)
        illustrationMarkDataList.append(data)
        setupNewIllustrationMarkView(with: data)
    }
    
    private func setupNewIllustrationMarkView(with data: IllustrationMarkModel) {
        let view = RecordingAddedIllustrationMarkView(frame: CGRect(x: 0, y: 0, width: illustrationMarkViewWidth, height: scrollContentView.bounds.height))
        scrollContentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let currentCenterXConstraintValue = data.centerXConstraintValue / CGFloat(currentZoomLevel.samplesPerLayer)
        setupIllustrationMarkConstraints(with: currentCenterXConstraintValue, view: view)
        
        view.data = data
        view.setupTimeLabel(with: data.timeInterval)
        view.setupTimeLabelAndRemoveButtonVisibility(isHidden: !data.isActive)
        view.removeMarkBlock = { [weak self, weak view] in
            if let index = self?.illustrationMarkDataList.firstIndex(where: { $0.timeInterval == data.timeInterval }) {
                self?.illustrationMarkDataList.remove(at: index)
                view?.removeFromSuperview()
            }
        }
        view.bringMarkViewToFrontBlock = { [weak self, weak view] in
            guard let strongSelf = self, let strongView = view else { return }
            strongSelf.hideScrollContentViewSubviews()
            strongSelf.setAllIllustrationMarksInactive()
            strongSelf.scrollContentView.bringSubview(toFront: strongView)
            strongView.setupTimeLabelAndRemoveButtonVisibility(isHidden: false)
        }
    }
    
    private func setAllIllustrationMarksInactive() {
        var dataList: [IllustrationMarkModel] = []
        illustrationMarkDataList.forEach {
            let data = IllustrationMarkModel.init(timeInterval: $0.timeInterval, centerXConstraintValue: $0.centerXConstraintValue, isActive: false)
            dataList.append(data)
        }

        illustrationMarkDataList = dataList
    }
    
    private func hideScrollContentViewSubviews() {
        scrollContentView.subviews.forEach {
            if let subview = $0 as? RecordingAddedIllustrationMarkView {
                subview.setupTimeLabelAndRemoveButtonVisibility(isHidden: true)
            }
        }
    }
    
    private func setupIllustrationMarkConstraints(with centerXConstraintValue: CGFloat, view: UIView) {
        NSLayoutConstraint.build(item: view,
                                 attribute: .top,
                                 toItem: scrollContentView,
                                 attribute: .top,
                                 constant: 5).isActive = true
        NSLayoutConstraint.build(item: scrollContentView,
                                 attribute: .bottom,
                                 toItem: view,
                                 attribute: .bottom,
                                 constant: 5).isActive = true
        
        NSLayoutConstraint.build(item: view,
                                 attribute: .width,
                                 toItem: nil,
                                 attribute: .notAnAttribute,
                                 constant: illustrationMarkViewWidth).isActive = true
        
        NSLayoutConstraint.build(item: view,
                                 attribute: .centerX,
                                 toItem: scrollContentView,
                                 attribute: .centerX,
                                 constant: centerXConstraintValue).isActive = true
    }
    
    func setupScrollViewWithScrollContentView() {
        let width = calculateScrollContentViewWidth()
        scrollView.contentInset = waveformPlot.waveformView.contentInset
        scrollContentViewWidthConstraint = NSLayoutConstraint.build(item: scrollContentView,
                                                  attribute: .width,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  constant: width)
        scrollContentViewWidthConstraint.isActive = true
    }
    
    private func updateScrollViewWithScrollContentView() {
        let width = calculateScrollContentViewWidth()
        scrollView.contentInset = waveformPlot.waveformView.contentInset
        scrollContentViewWidthConstraint.constant = width
    }
    
    private func calculateScrollContentViewWidth() -> CGFloat {
        waveformPlot.waveformView.layoutIfNeeded() // TODO: updating view in different way
        let width = waveformPlot.waveformView.waveformViewContentSize.width + (2 * illustrationMarkViewWidth)
        return width
    }
}

extension WaveformWithIllustrationsPlot: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        waveformPlot.waveformView.contentOffset = scrollView.contentOffset
        redrawIllustrationMarkViews(contentOffset: scrollView.contentOffset)
    }
    
    private func redrawIllustrationMarkViews(contentOffset: CGPoint) {
        illustrationMarkDataList.forEach { data in
            let leftOffset = (data.centerXConstraintValue / CGFloat(currentZoomLevel.samplesPerLayer)) + (scrollContentViewWidthConstraint.constant / 2) - (contentOffset.x - scrollView.contentInset.left)
            let subview = scrollContentView.subviews.first(where: { view in
                (view as? RecordingAddedIllustrationMarkView)?.data.centerXConstraintValue == data.centerXConstraintValue
            })
            
            if (leftOffset < leftMarkViewVisibilityMargin || leftOffset > rightMarkViewVisibilityMargin) && subview != nil {
                scrollContentView.willRemoveSubview(subview!)
                subview!.removeFromSuperview()
                print("removed mark view")
            }
            
            if leftOffset > leftMarkViewVisibilityMargin && leftOffset < rightMarkViewVisibilityMargin && subview == nil {
                setupNewIllustrationMarkView(with: data)
                print("added mark view")
            }
        }
    }
}

extension WaveformWithIllustrationsPlot: WaveformPlotDelegate {
    func zoomLevelDidChange(_ zoomLevel: ZoomLevel) {
        scrollContentView.subviews.forEach { $0.removeFromSuperview() }
        updateScrollViewWithScrollContentView()
        currentZoomLevel = zoomLevel
        redrawIllustrationMarkViews(contentOffset: scrollView.contentOffset)
    }
    
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval) {
        delegate?.currentTimeIntervalDidChange(timeInterval)
    }
    
    func contentOffsetDidChange(_ contentOffset: CGPoint) {
        scrollView.bounds = CGRect(x: contentOffset.x,
                                   y: contentOffset.y,
                                   width: scrollView.bounds.size.width,
                                   height: scrollView.bounds.size.height)
        scrollView.contentOffset = contentOffset
    }
}
*/
