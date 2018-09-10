//
//  UIScrollView+Extension.swift
//  Waveform
//
//  Created by Robert Mietelski on 03.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

enum ScrollDirection {
    case top
    case right
    case bottom
    case left
    case center
    
    func contentOffsetWith(scrollView: UIScrollView) -> CGPoint {
        var contentOffset = CGPoint.zero
        switch self {
        case .top:
            contentOffset = CGPoint(x: 0, y: -scrollView.contentInset.top)
        case .right:
            contentOffset = CGPoint(x: scrollView.contentSize.width - scrollView.bounds.size.width, y: 0)
        case .bottom:
            contentOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
        case .left:
            contentOffset = CGPoint(x: -scrollView.contentInset.left, y: 0)
        case .center:
            let x = scrollView.contentSize.width - (scrollView.bounds.size.width - (scrollView.bounds.size.width / 2))
            contentOffset = CGPoint(x: x, y: 0)
        }
        return contentOffset
    }
}

extension UIScrollView {
    func scrollTo(direction: ScrollDirection, animated: Bool = true) {
        self.setContentOffset(direction.contentOffsetWith(scrollView: self), animated: animated)
    }
}
