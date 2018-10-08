//
//  IllustrationMark.swift
//  Waveform
//
//  Created by Piotr Olech on 20/09/2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

struct IllustrationMark {
    
    // MARK: - Public properties
    
    let timeInterval: TimeInterval
    let imageURL: URL?
    
    // MARK: - Initialization
    
    init(timeInterval: TimeInterval, imageURL: URL? = nil) {
        self.timeInterval = timeInterval
        self.imageURL = imageURL
    }
}

extension IllustrationMark: Hashable {
    var hashValue: Int {
        return timeInterval.hashValue
    }
}

extension IllustrationMark: Equatable {
    static func == (lhs: IllustrationMark, rhs: IllustrationMark) -> Bool {
        return lhs.timeInterval == rhs.timeInterval
    }
}
