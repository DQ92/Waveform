//
//  Zoom.swift
//  Waveform
//
//  Created by Robert Mietelski on 20.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

struct Zoom {
    
    // MARK: - Public properties
    
    var isMinimum: Bool {
        return self.currentLevel == self.values.count - 1
    }
    
    var isMaximum: Bool {
        return self.currentLevel == 0
    }
    
    var numberOfLevels: Int {
        return self.values.count
    }
    
    var value: Int {
        return self.values[self.currentLevel]
    }
    
    var percent: CGFloat {
        return CGFloat(self.currentLevel + 1) / CGFloat(max(self.numberOfLevels, 1))
    }
    
    // MARK: - Private properties
    
    private var values: [Int] = []
    private var currentLevel: Int = 0
    
    // MARK: - Initialization
    
    init(samplesPerPoint: CGFloat = 1.0) {
        self.values = Set(arrayLiteral: 1, Int(ceil(samplesPerPoint))).sorted()
    }
    
    // Access methods
    
    mutating func `in`() {
        if !self.isMaximum {
            self.currentLevel -= 1
        }
    }
    
    mutating func out() {
        if !self.isMinimum {
            self.currentLevel += 1
        }
    }
}
