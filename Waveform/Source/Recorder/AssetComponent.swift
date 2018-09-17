//
//  AssetComponent.swift
//  Waveform
//
//  Created by Robert Mietelski on 14.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import AVFoundation

struct AssetComponent {
    
    // MARK: - Public properties
    
    let fileName: String
    let timeRange: CMTimeRange
    
    // MARK: - Access methods
    
    func loadAsset(directoryUrl: URL) -> AVAsset {
        let assetUrl = directoryUrl.appendingPathComponent(fileName)
        return AVAsset(url: assetUrl)
    }
}
