//
//  WaveformWithIllustrationsPlot.swift
//  Waveform
//
//  Created by Piotr Olech on 17/09/2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

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
        waveformPlotView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveformPlotView)
        
        return waveformPlotView
    }()
    
    // MARK: - Private properties
    
    private var autoScrollTimer: Timer!
    private var illustrationMarkViewWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.08
    }
    private var illustrationMarkDataList: [IllustrationMarkModel] = []
    
    // MARK: - Private constants
    
    private let leftMarkViewVisibilityMargin = UIScreen.main.bounds.width * 0.5
    private let rightMarkViewVisibilityMargin = 2 * UIScreen.main.bounds.width
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupConstraints()
        waveformPlot.isUserInteractionEnabled = false
        waveformPlot.backgroundColor = .clear
        waveformPlot.waveformView.backgroundColor = .clear
        waveformPlot.timelineView.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupConstraints()
        waveformPlot.isUserInteractionEnabled = false
        waveformPlot.backgroundColor = .clear
        waveformPlot.waveformView.backgroundColor = .clear
        waveformPlot.timelineView.backgroundColor = .clear
    }
    
    private func setupConstraints() {
        scrollView.setupConstraint(attribute: .leading, toItem: self, attribute: .leading)
        scrollView.setupConstraint(attribute: .trailing, toItem: self, attribute: .trailing)
        scrollView.setupConstraint(attribute: .top, toItem: self, attribute: .top)
        scrollView.setupConstraint(attribute: .bottom, toItem: self, attribute: .bottom)
        
        scrollContentView.setupConstraint(attribute: .leading, toItem: scrollView, attribute: .leading, constant: -(illustrationMarkViewWidth))
        scrollContentView.setupConstraint(attribute: .trailing, toItem: scrollView, attribute: .trailing, constant: -(illustrationMarkViewWidth))
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
        centerXConstraintValue = round(centerXConstraintValue * 10) / 10.0
        let currentTimeInterval = waveformPlot.waveformView.currentTimeInterval
        
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
        setupIllustrationMarkConstraints(with: data.centerXConstraintValue, view: view)
        
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
    
    func setupContentViewOfScrollView() {
        waveformPlot.waveformView.layoutIfNeeded() // TODO: updating view in different way
        let width = waveformPlot.waveformView.waveformViewContentSize.width
        scrollView.contentInset = waveformPlot.waveformView.contentInset
        let constraint = NSLayoutConstraint.build(item: scrollContentView,
                                                  attribute: .width,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  constant: width)
        constraint.isActive = true
    }
}

extension WaveformWithIllustrationsPlot: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        waveformPlot.waveformView.contentOffset = scrollView.contentOffset
        illustrationMarkDataList.forEach { data in
            let leftOffset = data.centerXConstraintValue + (scrollContentView.bounds.width / 2) - (scrollView.contentOffset.x - scrollView.contentInset.left)

            // print("leftOffset: \(leftOffset)       constraint: \(element.value.centerXConstraintValue)")
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
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
}

extension WaveformWithIllustrationsPlot: LeadingLineTimeUpdaterDelegate {
    func timeIntervalDidChange(with timeInterval: TimeInterval) {
        waveformPlot.waveformView.timeIntervalDidChange(with: timeInterval)
    }
    
    func scrollToTheEnd() {
        let point = scrollView.contentOffset
        scrollView.setContentOffset(point, animated: false)
        waveformPlot.waveformView.contentOffset = point
        
        autoScrollTimer?.invalidate()
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 0.01,
                                               target: self,
                                               selector: #selector(scrollContentOffset),
                                               userInfo: nil,
                                               repeats: true)
    }
    
    @objc func scrollContentOffset() {
        let difference: CGFloat = CGFloat(WaveformConfiguration.microphoneSamplePerSecond) / 100
        let finalPosition: CGFloat = scrollView.contentOffset.x + difference
        let point = CGPoint(x: finalPosition, y: 0.0)
        scrollView.bounds = CGRect(x: point.x,
                                   y: point.y,
                                   width: scrollView.bounds.size.width,
                                   height: scrollView.bounds.size.height)
        
        waveformPlot.waveformView.contentOffset = scrollView.contentOffset
        waveformPlot.waveformView.scrollContentOffset()
    }
    
    func stopScrolling() {
        autoScrollTimer.invalidate()
    }
}
