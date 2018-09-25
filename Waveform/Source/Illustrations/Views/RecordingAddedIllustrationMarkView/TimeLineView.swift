//
//  TimeLineView.swift
//  Soou.me
//
//  Created by Piotr Olech on 13/09/2018.
//  Copyright © 2018 altconnect. All rights reserved.
//

import UIKit

class TimeLineView: UIView {
    
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
        
        context.setLineWidth(1)
        context.setFillColor(UIColor.green.cgColor)
        context.setStrokeColor(UIColor.green.cgColor)
        
        let ellipseWidth = rect.width / 2
        context.addEllipse(in: CGRect(x: rect.midX / 2, y: 0, width: ellipseWidth, height: ellipseWidth))
        context.addEllipse(in: CGRect(x: rect.midX / 2, y: rect.maxY - ellipseWidth, width: ellipseWidth, height: ellipseWidth))
        context.fillPath()

        context.move(to: CGPoint(x: rect.midX, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.height))
        context.strokePath()
    }
}
