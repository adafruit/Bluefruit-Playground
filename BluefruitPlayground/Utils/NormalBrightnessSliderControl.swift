//
//  NormalBrightnessSliderControl.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import FlexColorPicker

// From https://github.com/RastislavMirek/FlexColorPicker/issues/1
struct NormalBrightnessSliderDelegate: ColorSliderDelegate {
    func modifiedColor(from color: HSBColor, with value: CGFloat) -> HSBColor {
        return color.withBrightness(value)
    }

    func valueAndGradient(for color: HSBColor) -> (value: CGFloat, gradientStart: UIColor, gradientEnd: UIColor) {
        return (color.brightness, color.withBrightness(0).toUIColor(), color.withBrightness(1).toUIColor())
    }
}

class NormalBrightnessSliderControl: ColorSliderControl {
    public override func commonInit() {
        sliderDelegate = NormalBrightnessSliderDelegate()
        super.commonInit()
    }
}
