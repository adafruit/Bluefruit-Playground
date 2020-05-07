//
//  AdafruitBoard+FlashNeopixels.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 07/05/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit

extension AdafruitBoard {
    
    // MARK: - Utils
    func neopixelFlashLightSequence(color: UIColor) {
        guard let neopixelPixelsCount = neopixelPixelsCount, neopixelPixelsCount > 0 else { return }
        neopixelStartLightSequence(FlashLightSequence(baseColor: color, numPixels: neopixelPixelsCount), speed: 1, repeating: false, sendLightSequenceNotifications: false)
    }
}
