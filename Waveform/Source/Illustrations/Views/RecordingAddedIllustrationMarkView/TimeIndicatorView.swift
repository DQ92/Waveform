//
//  TimeIndicatorView.swift
//  Soou.me
//
//  Created by Piotr Olech on 13/09/2018.
//  Copyright © 2018 altconnect. All rights reserved.
//

import UIKit

class TimeIndicatorView: UIView {
    
    // MARK: - Public properties
    
    var indicatorColor: UIColor = UIColor.green {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var indicatorWidth: CGFloat = 1.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineWidth(self.indicatorWidth)
        context.setFillColor(self.indicatorColor.cgColor)
        context.setStrokeColor(self.indicatorColor.cgColor)
        
        let ellipseWidth = rect.width / 2
        context.addEllipse(in: CGRect(x: rect.midX / 2, y: 0, width: ellipseWidth, height: ellipseWidth))
        context.addEllipse(in: CGRect(x: rect.midX / 2, y: rect.maxY - ellipseWidth, width: ellipseWidth, height: ellipseWidth))
        context.fillPath()

        context.move(to: CGPoint(x: rect.midX, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.height))
        context.strokePath()
    }
    
    // MARK: - Access methods
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 7.0, height: super.intrinsicContentSize.height)
    }
}
