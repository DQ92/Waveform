//
// Created by Michał Kos on 2018-09-25.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

protocol FileDataLoaderProtocol {

    var fileDuration: TimeInterval! { get }

    func loadFile(with fileName: String,
                  and fileFormat: String,
                  completion: (_ fileFloatArray: [Float]) -> Void) throws
    func loadFile(with URL: URL, completion: (_ fileFloatArray: [Float]) -> Void) throws
}
