//
// Created by Michał Kos on 2018-09-25.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import AVFoundation

protocol FileDataLoaderProtocol {
    var duration: TimeInterval { get }
    
    func loadFile(with fileName: String,
                  and fileFormat: String,
                  completion: (_ fileFloatArray: [Float], _ timeInterval: TimeInterval) -> Void) throws
    func loadFile(with URL: URL, completion: (_ fileFloatArray: [Float], _ timeInterval: TimeInterval) -> Void) throws
}
