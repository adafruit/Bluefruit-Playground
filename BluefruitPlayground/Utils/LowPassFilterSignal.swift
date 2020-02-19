//
//  LowPassFilterSignal.swift
//  BluefruitPlayground
//
//  Created by Trevor Beaton on 04/02/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import Foundation

struct LowPassFilterSignal {
    /// Current signal value
    var value: Float

    /// A scaling factor in the range 0.0..<1.0 that determines
    /// how resistant the value is to change
    let filterFactor: Float

    /// Update the value, using filterFactor to attenuate changes
    mutating func update(newValue: Float) {
        value = filterFactor * value + (1.0 - filterFactor) * newValue
    }
}
