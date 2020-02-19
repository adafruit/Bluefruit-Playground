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

    // MARK: - Extra events
    // Add events for changing value on touch up. Those events are not included on the base BrightnessSliderControl
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if let location = event?.allTouches?.first?.location(in: self.contentView), self.contentView.bounds.contains(location) {
            sendActions(for: .touchUpInside)
        } else {
            sendActions(for: .touchUpOutside)
        }
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        sendActions(for: .touchCancel)
    }
}
