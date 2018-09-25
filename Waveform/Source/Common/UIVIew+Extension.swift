//
//  UIVIew+Extension.swift
//  Waveform
//
//  Created by Robert Mietelski on 06.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

extension UIView {
    public func setupConstraint(attribute attr1: NSLayoutAttribute,
                                relatedBy relation: NSLayoutRelation = .equal,
                                toItem view2: Any? = nil,
                                attribute attr2: NSLayoutAttribute = .notAnAttribute,
                                multiplier: CGFloat = 1.0,
                                constant: CGFloat = 0.0,
                                priority: UILayoutPriority = .required) {
        
        NSLayoutConstraint.build(item: self,
                                 attribute: attr1,
                                 relatedBy: relation,
                                 toItem: view2,
                                 attribute: attr2,
                                 multiplier: multiplier,
                                 constant: constant,
                                 priority: priority).isActive = true
    }
}
