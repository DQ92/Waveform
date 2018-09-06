//
// Created by Michał Kos on 06/09/2018.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation

protocol RecorderDelegate: class {
    func recorderStateDidChange(with state: RecorderState)
}
