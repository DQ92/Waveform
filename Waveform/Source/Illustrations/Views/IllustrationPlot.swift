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
    
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, samplesAtTimeIntervalIndex index: Int) -> [Sample]
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, timeIntervalWidthAtIndex index: Int) -> CGFloat
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, markAtPosition position: CGFloat) -> IllustrationMark?
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, positionForMark mark: IllustrationMark) -> CGFloat?
}

protocol IllustrationPlotDelegate: class {
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, contentOffsetDidChange contentOffset: CGPoint)
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, currentPositionDidChange position: CGFloat)
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, markDidSelect mark: IllustrationMark)
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, markDidDeselect mark: IllustrationMark)
    func illustrationPlot(_ illustrationPlot: IllustrationPlot, markDidRemove mark: IllustrationMark)
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
    
    var selectedMark: IllustrationMark? {
        willSet {
            if let mark = selectedMark, let markView = self.dictionary[mark] {
                markView?.setSelected(false)
            }
        }
        didSet {
            if let mark = selectedMark, let markView = self.dictionary[mark], let view = markView {
                self.contentView.bringSubview(toFront: view)
                view.setSelected(true)
            }
        }
    }
    
    // MARK: - Views
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
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
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss:SS"
        
        return formatter
    }()
    
    private var dictionary: [IllustrationMark: IllustrationMarkView?] = [:]
    
    var illustrationMarkViewWidth: CGFloat = UIScreen.main.bounds.width * 0.1
    
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
    }
    
    private func setupConstraints() {
        self.setupConstraint(item: self.waveformPlot, attribute: .leading, toItem: self, attribute: .leading)
        self.setupConstraint(item: self.waveformPlot, attribute: .trailing, toItem: self, attribute: .trailing)
        self.setupConstraint(item: self.waveformPlot, attribute: .bottom, toItem: self, attribute: .bottom, constant: -50)
        self.setupConstraint(item: self.waveformPlot, attribute: .height, toItem: self, attribute: .height, multiplier: 0.6)
        
        self.setupConstraint(item: self.scrollView, attribute: .leading, toItem: self, attribute: .leading)
        self.setupConstraint(item: self.scrollView, attribute: .trailing, toItem: self, attribute: .trailing)
        self.setupConstraint(item: self.scrollView, attribute: .top, toItem: self, attribute: .top)
        self.setupConstraint(item: self.scrollView, attribute: .height, toItem: self, attribute: .height, multiplier: 0.9)
        
        self.setupConstraint(item: self.contentView, attribute: .leading, toItem: self.scrollView, attribute: .leading, constant: -(illustrationMarkViewWidth * 0.5))
        self.setupConstraint(item: self.contentView, attribute: .trailing, toItem: self.scrollView, attribute: .trailing)
        self.setupConstraint(item: self.contentView, attribute: .top, toItem: self.scrollView, attribute: .top)
        self.setupConstraint(item: self.contentView, attribute: .bottom, toItem: self.scrollView, attribute: .bottom)
        self.setupConstraint(item: self.contentView, attribute: .centerY, toItem: self.scrollView, attribute: .centerY)
        
        self.contentWidthLayoutConstraint.isActive = true
    }

    // MARK: - Access methods
    
    func addMark(_ mark: IllustrationMark) {
        self.addMark(mark, at: self.currentPosition)
    }
    
    func reloadMark(at position: CGFloat) {
        guard let mark = self.dataSource?.illustrationPlot(self, markAtPosition: position), let markView = self.dictionary[mark] else {
            return
        }
        self.setupMark(mark, inView: markView)
    }
    
    func reloadMarks() {
        self.redrawMarks(relativeBy: self.currentPosition)
    }
    
    func reloadData() {
        self.waveformPlot.reloadData()
        self.reloadMarks()
    }
    
    // MARK: - Others
    
    private func addMark(_ mark: IllustrationMark, at position: CGFloat) {
        self.dictionary[mark] = self.createMark(mark, at: position)
    }
    
    private func createMark(_ mark: IllustrationMark, at position: CGFloat) -> IllustrationMarkView {
        let markView = IllustrationMarkView(frame: .zero)
        markView.translatesAutoresizingMaskIntoConstraints = false
        self.setupMark(mark, inView: markView)
        self.contentView.addSubview(markView)
        
        self.setupConstraint(item: markView, attribute: .top, toItem: self.contentView, attribute: .top)
        self.setupConstraint(item: markView, attribute: .bottom, toItem: self.contentView, attribute: .bottom)
        self.setupConstraint(item: markView, attribute: .width, attribute: .notAnAttribute,  constant: illustrationMarkViewWidth)
        self.setupConstraint(item: markView, attribute: .leading, toItem: self.contentView, attribute: .leading, constant: position)
        
        return markView
    }
    
    private func setupMark(_ mark: IllustrationMark, inView markView: IllustrationMarkView?) {
        markView?.setTime(self.dateFormatter.string(from: Date(timeIntervalSince1970: mark.timeInterval)))
        markView?.setImageUrl(mark.imageURL)
        markView?.setSelected(mark == self.selectedMark)
        markView?.delegate = self
    }
    
    private func redrawMarks(relativeBy currentPosition: CGFloat) {
        let leftBoundary = max(currentPosition - self.bounds.width, 0.0)
        let rightBoundary = min(currentPosition + self.bounds.width, self.waveformPlot.contentSize.width)
        let visibleRange = leftBoundary...rightBoundary
        let currentDictionary = self.dictionary

        for (mark, markView) in currentDictionary {
            guard let position = self.dataSource?.illustrationPlot(self, positionForMark: mark) else {
                continue
            }
            
            if visibleRange.contains(position) {
                if let view = markView {
                    self.setupMark(mark, inView: view)
                } else {
                    self.addMark(mark, at: position)
                }
            } else if let view = markView {
                view.removeFromSuperview()
                self.dictionary.updateValue(nil, forKey: mark)
            }
        }
    }
        
}

extension IllustrationPlot: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.currentPosition = scrollView.contentOffset.x + scrollView.contentInset.left
        self.redrawMarks(relativeBy: self.currentPosition)
        
        self.waveformPlot.contentOffset = scrollView.contentOffset
        self.delegate?.illustrationPlot(self, contentOffsetDidChange: scrollView.contentOffset)
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
        self.reloadMarks()
    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, contentOffsetDidChange contentOffset: CGPoint) {

    }
    
    func waveformPlot(_ waveformPlot: WaveformPlot, currentPositionDidChange position: CGFloat) {
        self.delegate?.illustrationPlot(self, currentPositionDidChange: position)
    }
}

extension IllustrationPlot: IllustrationMarkViewDelegate {
    func removeMark(in illustrationMarkView: IllustrationMarkView) {
        guard let mark = self.dictionary.first(where: { $1 === illustrationMarkView })?.key else {
            return
        }
        illustrationMarkView.removeFromSuperview()
        self.dictionary.removeValue(forKey: mark)
        
        self.delegate?.illustrationPlot(self, markDidRemove: mark)
    }
    
    func bringMarkToFront(in illustrationMarkView: IllustrationMarkView) {
        guard let currentMark = self.dictionary.first(where: { $1 === illustrationMarkView })?.key else {
            return
        }
        if let previousMark = self.selectedMark {
            self.delegate?.illustrationPlot(self, markDidDeselect: previousMark)
        }
        self.selectedMark = currentMark
        
        self.delegate?.illustrationPlot(self, markDidSelect: currentMark)
    }
}
