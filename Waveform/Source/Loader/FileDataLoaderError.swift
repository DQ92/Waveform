//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

enum FileDataLoaderError: Error {
    case pathOrFormatProvidedInvalid
    case openUrlFailed
    case setFormatFailed
    case retrieveFileLengthFailed
    case fileReadFailed
    case providedURLNotAcceptable
}
