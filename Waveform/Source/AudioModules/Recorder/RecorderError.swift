//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation

enum RecorderError: Error {
    case sessionCategoryInvalid(Error)
    case sessionActivationFailed(Error)
    case directoryDeletionFailed(Error)
    case directoryCreationFailed(Error)
    case directoryContentListingFailed(Error)
    case timeRangeInsertFailed(Error)
    case fileExportFailed
}
