//
//  NeopixelsUIUtils.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 10/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

struct NeopixelsUIUtils {
    // Config
    private static let kUIColorsMinBrightnessValue: CGFloat = 0.4        // Used only for the UI because the colors get too dark when the brightness is low, so we simulate that the minimum brighness is this
    
    
    static func visualBrightnessFromBrightness(_ brightness: CGFloat) -> CGFloat {
        let visualBrightness = brightness * (1 - NeopixelsUIUtils.kUIColorsMinBrightnessValue) + NeopixelsUIUtils.kUIColorsMinBrightnessValue
        return visualBrightness
    }
}
