//
//  Float+Clamped.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 04/02/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import Foundation

// MARK: - Float + Clamped
extension Float {
    func clamped( min: Float, max: Float) -> Float {
        
        if self < min {
            return min
        }
        else if self > max {
            return max
        }
        else {
            return self
        }
    }
}
