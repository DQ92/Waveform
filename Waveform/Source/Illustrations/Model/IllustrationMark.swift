//
//  IllustrationMark.swift
//  Waveform
//
//  Created by Piotr Olech on 20/09/2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

struct IllustrationMark: Hashable {
    let timeInterval: TimeInterval
    let centerXConstraintValue: CGFloat
    let imageURL: URL?
    let isActive: Bool
}
