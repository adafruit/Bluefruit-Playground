//
//  NormalBrightnessColorPickerController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import FlexColorPicker

class NormalBrightnessColorPickerController: ColorPickerController {

    @IBOutlet open var normalBrightnessSlider: NormalBrightnessSliderControl? {
           didSet {
               controlDidSet(newValue: normalBrightnessSlider, oldValue: oldValue)
           }
       }
}
