//
//  IllustrationPlot.swift
//  Waveform
//
//  Created by Piotr Olech on 17/09/2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

protocol IllustrationPlotDataSource: class {
    func timeInterval(in illustrationPlot: IllustrationPlot) -> TimeInterval
    func numberOfTimeInterval(in illustrationPlot: IllustrationPlot) -> Int
    func samplesPerLayer(for illustrationPlot: IllustrationPlot) -> CGFloat
    func illustrationMarks(for illustrationPlot: IllustrationPlot) -> [IllustrationMark]
    
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, samplesAtTimeIntervalIndex index: Int) -> [Sample]
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, timeIntervalWidthAtIndex index: Int) -> CGFloat
}

protocol IllustrationPlotDelegate: class {
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, contentOffsetDidChange contentOffset: CGPoint)
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, currentPositionDidChange position: CGFloat)
    
    func removeIllustrationMark(for timeInterval: TimeInterval)
    func setAllIllustrationMarksOfCurrentChapterInactive(except illustrationMarkData: IllustrationMark)
}

class IllustrationPlot: UIView, ScrollablePlot {

    // MARK: - Public properties
    
    weak var dataSource: IllustrationPlotDataSource?
    weak var delegate: IllustrationPlotDelegate?
    
    var contentOffset: CGPoint {
        set {
            self.scrollView.contentOffset = newValue
            self.waveformPlot.contentOffset = newValue
        }
        get {
            return self.scrollView.contentOffset
        }
    }
    
    var contentInset: UIEdgeInsets {
        set {
            self.scrollView.contentInset = UIEdgeInsets(top: newValue.top, left: newValue.left, bottom: newValue.bottom, right: newValue.right - illustrationMarkViewWidth * 0.5)
            self.waveformPlot.contentInset = newValue
        }
        get {
            return self.scrollView.contentInset
        }
    }
    
    var currentPosition: CGFloat = 0.0 {
        didSet {
            self.contentOffset = CGPoint(x: currentPosition - self.contentInset.left, y: 0.0)
            self.delegate?.illustrationPlot(self, currentPositionDidChange: currentPosition)
        }
    }
    
    var standardTimeIntervalWidth: CGFloat {
        set {
            self.waveformPlot.standardTimeIntervalWidth = newValue
        }
        get {
            return self.waveformPlot.standardTimeIntervalWidth
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
    
    var timeIndicatorView: UIView? {
        willSet {
            timeIndicatorView?.removeFromSuperview()
        }
        didSet {
            if let view = timeIndicatorView {
                view.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(view)
                
                self.setupConstraint(item: view, attribute: .top, toItem: self.waveformPlot, attribute: .top)
                self.setupConstraint(item: view, attribute: .bottom, toItem: self, attribute: .bottom)
                self.setupConstraint(item: view, attribute: .centerX, toItem: self.waveformPlot, attribute: .centerX)
            }
        }
    }
    
    // MARK: - Private attributes
    
    private lazy var contentWidthLayoutConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint.build(item: self.contentView, attribute: .width, constant: illustrationMarkViewWidth)
    }()
    
    var illustrationMarkViewWidth: CGFloat = UIScreen.main.bounds.width * 0.1
    
    // MARK: - Private constants
    
    private let leftMarkViewVisibilityMargin = UIScreen.main.bounds.width * 0.5
    private let rightMarkViewVisibilityMargin = 2 * UIScreen.main.bounds.width
    
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
        waveformPlot.isUserInteractionEnabled = false
        waveformPlot.backgroundColor = .clear
        
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    private func setupConstraints() {
        self.setupConstraint(item: self.waveformPlot, attribute: .leading, toItem: self, attribute: .leading)
        self.setupConstraint(item: self.waveformPlot, attribute: .trailing, toItem: self, attribute: .trailing)
        self.setupConstraint(item: self.waveformPlot, attribute: .bottom, toItem: self, attribute: .bottom, constant: -50)
        self.setupConstraint(item: self.waveformPlot, attribute: .height, toItem: self, attribute: .height, multiplier: 0.6, constant: 0)
        
        self.setupConstraint(item: self.scrollView, attribute: .leading, toItem: self, attribute: .leading)
        self.setupConstraint(item: self.scrollView, attribute: .trailing, toItem: self, attribute: .trailing)
        self.setupConstraint(item: self.scrollView, attribute: .top, toItem: self, attribute: .top)
        self.setupConstraint(item: self.scrollView, attribute: .height, toItem: self, attribute: .height, multiplier: 0.9, constant: 0)
        
        self.setupConstraint(item: self.contentView, attribute: .leading, toItem: self.scrollView, attribute: .leading, constant: -(illustrationMarkViewWidth * 0.5))
        self.setupConstraint(item: self.contentView, attribute: .trailing, toItem: self.scrollView, attribute: .trailing)
        self.setupConstraint(item: self.contentView, attribute: .top, toItem: self.scrollView, attribute: .top)
        self.setupConstraint(item: self.contentView, attribute: .bottom, toItem: self.scrollView, attribute: .bottom)
        self.setupConstraint(item: self.contentView, attribute: .centerY, toItem: self.scrollView, attribute: .centerY)
        
        self.contentWidthLayoutConstraint.isActive = true
    }
    
    // MARK: - Illustration marks setup
    
    func addIllustrationMark(with data: IllustrationMark, for samplesPerLayer: CGFloat) {
        hideScrollContentViewSubviews()
        delegate?.setAllIllustrationMarksOfCurrentChapterInactive(except: data)
        setupNewIllustrationMarkView(with: data, for: samplesPerLayer)
    }
    
    func setupIllustrationMarks(with illustrationMarksData: [IllustrationMark], for samplesPerLayer: CGFloat) {
        illustrationMarksData.forEach {
            setupNewIllustrationMarkView(with: $0, for: samplesPerLayer)
        }
    }
    
    private func setupNewIllustrationMarkView(with data: IllustrationMark, for samplesPerLayer: CGFloat) {
        let view = IllustrationMarkView(frame: .zero)
        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let currentCenterXConstraintValue = data.centerXConstraintValue / samplesPerLayer
        setupIllustrationMarkConstraints(with: currentCenterXConstraintValue, view: view)
        
        view.data = data
        view.setupTimeLabel(with: data.timeInterval)
        view.setupImageView(with: data.imageURL)
        view.setupTimeLabelAndRemoveButtonVisibility(isHidden: !data.isActive)
        view.removeMarkBlock = { [weak self, weak view] in
            self?.delegate?.removeIllustrationMark(for: data.timeInterval)
            view?.removeFromSuperview()
        }
        view.bringMarkViewToFrontBlock = { [weak self, weak view] in
            guard let strongSelf = self, let strongView = view else { return }
            strongSelf.hideScrollContentViewSubviews()
            strongSelf.delegate?.setAllIllustrationMarksOfCurrentChapterInactive(except: data)
            strongSelf.contentView.bringSubview(toFront: strongView)
            strongView.setupTimeLabelAndRemoveButtonVisibility(isHidden: false)
        }
    }
    
    private func setupIllustrationMarkConstraints(with centerXConstraintValue: CGFloat, view: UIView) {
        self.setupConstraint(item: view, attribute: .top, toItem: contentView, attribute: .top)
        self.setupConstraint(item: view, attribute: .bottom, toItem: contentView, attribute: .bottom)
        self.setupConstraint(item: view, attribute: .width, attribute: .notAnAttribute,  constant: illustrationMarkViewWidth)
        self.setupConstraint(item: view, attribute: .centerX, toItem: contentView, attribute: .centerX, constant: centerXConstraintValue)
    }
    
    private func hideScrollContentViewSubviews() {
        contentView.subviews.forEach {
            if let subview = $0 as? IllustrationMarkView {
                subview.setupTimeLabelAndRemoveButtonVisibility(isHidden: true)
            }
        }
    }
    
    private func reloadIllustrationMarkViews() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        redrawIllustrationMarkViews(contentOffset: scrollView.contentOffset)
    }
    
    // MARK: - Access methods
    
    func reloadData() {
        self.waveformPlot.reloadData()
        reloadIllustrationMarkViews()
    }
    
    func calculateXConstraintForCurrentWaveformPosition() -> CGFloat {
        let halfOfScrollContentViewWidth = -(contentView.bounds.width / 2)
        let centerXConstraintValue = halfOfScrollContentViewWidth + scrollView.contentInset.left + scrollView.contentOffset.x + illustrationMarkViewWidth * 0.5
        return centerXConstraintValue
    }
}

extension IllustrationPlot: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentPosition = scrollView.contentOffset.x + scrollView.contentInset.left
        waveformPlot.contentOffset = scrollView.contentOffset
        
        redrawIllustrationMarkViews(contentOffset: scrollView.contentOffset)
    }
    
    private func redrawIllustrationMarkViews(contentOffset: CGPoint) {
        guard let samplesPerLayer = dataSource?.samplesPerLayer(for: self) else { return }
        dataSource?.illustrationMarks(for: self).forEach { data in
            let leftOffset = (data.centerXConstraintValue / samplesPerLayer) + (contentWidthLayoutConstraint.constant / 2) - (contentOffset.x - scrollView.contentInset.left)
            let subview = contentView.subviews.first(where: { view in
                (view as? IllustrationMarkView)?.data.centerXConstraintValue == data.centerXConstraintValue
            })
            
            if (leftOffset < leftMarkViewVisibilityMargin || leftOffset > rightMarkViewVisibilityMargin) && subview != nil {
                contentView.willRemoveSubview(subview!)
                subview!.removeFromSuperview()
            }
            
            if leftOffset > leftMarkViewVisibilityMargin && leftOffset < rightMarkViewVisibilityMargin && subview == nil {
                setupNewIllustrationMarkView(with: data, for: samplesPerLayer)
            }
        }
    }
}

extension IllustrationPlot: WaveformPlotDataSource {
    func timeInterval(in waveformPlot: WaveformPlot) -> TimeInterval {
        guard let result = self.dataSource?.timeInterval(in: self) else {
            return 0
        }
        return result
    }
    
    func numberOfTimeIntervals(in waveformPlot: WaveformPlot) -> Int {
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
    func waveformPlot(_ waveformPlot: WaveformPlot, contentSizeDidChange contentSize: CGSize) {
        self.contentWidthLayoutConstraint.constant = contentSize.width + illustrationMarkViewWidth
        reloadIllustrationMarkViews()
    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, contentOffsetDidChange contentOffset: CGPoint) {

    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, currentPositionDidChange position: CGFloat) {
        self.delegate?.illustrationPlot(self, currentPositionDidChange: position)
    }
}
