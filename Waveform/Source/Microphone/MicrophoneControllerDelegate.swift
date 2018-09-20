//
// Created by Michał Kos on 2018-09-19.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation

protocol MicrophoneControllerDelegate {
    func processSampleData(_ data: Float) -> Void
}
