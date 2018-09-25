//
//  Operators.swift
//  Waveform
//
//  Created by Michał Kos on 10/09/2018.
//  Copyright © 2018 Daniel Kuta. All rights reserved.
//

import Foundation

// MARK: - Error handling

func ~><T>(expression: @autoclosure () throws -> T,
           errorTransform: (Error) -> Error) throws -> T {
    do {
        return try expression()
    } catch {
        throw errorTransform(error)
    }
}
