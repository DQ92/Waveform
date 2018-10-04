//
//  IllustrationPlotDataManager.swift
//  Waveform
//
//  Created by Robert Mietelski on 01.10.2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import UIKit

class IllustrationPlotDataManager: WaveformPlotDataManager {
    
    // MARK: - Public properties
    
    var illustrationMarksDatasource: [Int: [IllustrationMark]] = [:]
    
    // MARK: - Access methods
    
    func checkIfIllustrationMarkExistsAtCurrentTime(for chapterId: Int, and timeInterval: TimeInterval) -> Bool {
        let value = illustrationMarksDatasource[chapterId]?.contains(where: { $0.timeInterval == timeInterval })
        return value ?? false
    }
    
    func appendIllustrationMarkData(for chapterId: Int, with data: IllustrationMark) {
        if illustrationMarksDatasource[chapterId] != nil {
            illustrationMarksDatasource[chapterId]?.append(data)
        } else {
            illustrationMarksDatasource[chapterId] = [data]
        }
    }
    
    func updateIllustrationMarkDatasource(for chapterId: Int, with data: IllustrationMark) {
        if var values = illustrationMarksDatasource[chapterId] {
            if let index = values.firstIndex(where: { $0.timeInterval == data.timeInterval }) {
                values[index] = data
            } else {
                values.append(data)
            }
            illustrationMarksDatasource[chapterId] = values
        } else {
            illustrationMarksDatasource[chapterId] = [data]
        }
    }
}
