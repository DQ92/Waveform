//
// Created by Michał Kos on 2018-09-19.
// Copyright (c) 2018 Andrew L. Jaffee. All rights reserved.
//

import Foundation

enum ZoomType {
    case none
    case variable(scale: Int)
    case max

    func zoomScale() -> Int {
        switch self {
            case .none:
                return 1
            case .variable(let scale):
                return scale
            case .max:
                return 10
        }
    }
}
