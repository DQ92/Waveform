//
//  MovementCoordinator.swift
//  Waveform
//
//  Created by Robert Mietelski on 30.09.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class MovementCoordinator {
    
    // MARK: - Private attributes
    
    private weak var plot: ScrollablePlot?
    private var offset: CGFloat = 0.0
    private var timer: Timer?
    
    // MARK: - Initialization
    
    init(plot: ScrollablePlot?) {
        self.plot = plot
    }
    
    // MARK: - Access methods
    
    func startScrolling(stepWidth: CGFloat, timeInterval: TimeInterval = 0.01) {
        guard self.timer == nil else {
            return
        }
        self.offset = stepWidth
        
        self.timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                          target: self,
                                          selector: #selector(updateCounter),
                                          userInfo: nil,
                                          repeats: true)
    }
    
    func stopScrolling() {
        if let timer = self.timer {
            timer.invalidate()
        }
        self.timer = nil
    }
    
    // MARK: - Selectors
    
    @objc private func updateCounter() {
        self.plot?.currentPosition += self.offset
    }
}
