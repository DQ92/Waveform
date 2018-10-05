//
// Created by Michał Kos on 2018-10-05.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

enum FileDataLoaderState {
    case loading
    case loaded(values: [Float], duration: TimeInterval)
}
