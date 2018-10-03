//
//  IllustrationPlotDataManager.swift
//  Waveform
//
//  Created by Robert Mietelski on 01.10.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class IllustrationPlotDataManager: WaveformPlotDataManager {
    var illustrationMarksDatasource: [Int: [IllustrationMarkModel]] = [:]
    
    func updateIllustrationMarkDatasource(for chapterId: Int, with data: IllustrationMarkModel) {
        
    }
}
