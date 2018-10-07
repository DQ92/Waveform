//
//  IllustrationPlotDataManager.swift
//  Waveform
//
//  Created by Robert Mietelski on 01.10.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class IllustrationPlotDataManager: WaveformPlotDataManager {
    
    // MARK: - Private properties
    
    private var markDictionary: [CGFloat: IllustrationMark] = [:]
    
    // MARK: - Access methods
    
    func containsMark(_ mark: IllustrationMark) -> Bool {
        return markDictionary.contains { $0.value == mark }
    }
    
    func setMark(_ mark: IllustrationMark, at position: CGFloat) {
        self.markDictionary[position] = mark
    }
    
    func position(for mark: IllustrationMark) -> CGFloat? {
        guard let position = self.markDictionary.first(where: { $1 == mark })?.key else {
            return nil
        }
        return position / CGFloat(self.zoomLevel.samplesPerLayer)
    }
    
    func mark(at position: CGFloat) -> IllustrationMark? {
        return self.markDictionary[position]
    }

    func removeMark(at position: CGFloat) {
        self.markDictionary.removeValue(forKey: position)
    }
    
    func removeMarks() {
        self.markDictionary = [:]
    }
}
