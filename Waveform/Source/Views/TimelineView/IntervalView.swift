//
//  IntervalView.swift
//  Waveform
//
//  Created by Robert Mietelski on 06.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

class IntervalView: UIView {
    
    // MARK: - Public attributes
    
    var intervalWidth: CGFloat = 100 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var lineWidth: CGFloat = 1.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var lineColor: UIColor = UIColor.gray {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var sublineHeight: CGFloat = 7.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var numberOfSublines: Int = 3 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    private func commonInit() {
        self.backgroundColor = .white
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.setLineWidth(self.lineWidth)
        context.setStrokeColor(self.lineColor.cgColor)
        context.move(to: CGPoint(x: 0.0, y: rect.height))
        context.addLine(to: CGPoint(x: rect.width, y: rect.height))
        
        let sublineDistance = (self.intervalWidth / CGFloat(self.numberOfSublines + 1))
        var lineX: CGFloat = 0.0
        
        while lineX < rect.width {
            context.move(to: CGPoint(x: lineX, y: 0.0))
            context.addLine(to: CGPoint(x: lineX, y: rect.height))
            
            let nextLinePosition = lineX + self.intervalWidth
            var sublineX = lineX + sublineDistance
            
            repeat {
                context.move(to: CGPoint(x: sublineX, y: rect.height - self.sublineHeight))
                context.addLine(to: CGPoint(x: sublineX, y: rect.height))
                sublineX += sublineDistance
            } while sublineX < nextLinePosition
            
            lineX += self.intervalWidth
        }
        context.move(to: CGPoint(x: lineX, y: 0.0))
        context.addLine(to: CGPoint(x: lineX, y: rect.height))
        context.strokePath()
    }
}
