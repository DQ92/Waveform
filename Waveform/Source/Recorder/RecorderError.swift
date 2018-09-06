//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation

enum RecorderError: Error {
    case sessionCategoryInvalid(Error)
    case sessionActivationFailed(Error)
    case noMicrophoneAccess
    case directoryDeletionFailed(Error)
    case directoryCreationFailed(Error)
    case directoryContentListingFailed(Error)
    case timeRangeInsertFailed(Error)
}
