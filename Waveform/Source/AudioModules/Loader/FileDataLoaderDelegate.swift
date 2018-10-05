//
// Created by Michał Kos on 2018-10-05.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

protocol FileDataLoaderDelegate {
    func loaderStateDidChange(with state: FileDataLoaderState)
}
