//
//  UIColor+Interpolate.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 30/01/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit

extension UIColor {
    // based on: https://stackoverflow.com/questions/22868182/uicolor-transition-based-on-progress-value
    func interpolateRGBColorTo(end:UIColor, fraction:CGFloat) -> UIColor {
        var f = max(0, fraction)
        f = min(1, fraction)
        guard var c1 = self.cgColor.components, var c2 = end.cgColor.components else { return self }
        // Convert 2 components colors to 4 components
        if c1.count == 2 {
            let whiteComponent = c1[0]
            let alphaComponent = c1[1]
            c1 = [whiteComponent, whiteComponent, whiteComponent, alphaComponent]
        }
        if c2.count == 2 {
            let whiteComponent = c2[0]
            let alphaComponent = c2[1]
            c2 = [whiteComponent, whiteComponent, whiteComponent, alphaComponent]
        }
        
        // Interpolate
        let r = c1[0] + (c2[0] - c1[0]) * f
        let g = c1[1] + (c2[1] - c1[1]) * f
        let b = c1[2] + (c2[2] - c1[2]) * f
        let a = c1[3] + (c2[3] - c1[3]) * f
        return UIColor.init(red:r, green:g, blue:b, alpha:a)
    }

     // Note:  getHue can be negative from iOS 10
    func interpolateHSVColorFrom(end: UIColor, fraction: CGFloat) -> UIColor {
        var f = max(0, fraction)
        f = min(1, fraction)
        var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        self.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        end.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)
        let h = h1 + (h2 - h1) * f
        let s = s1 + (s2 - b1) * f
        let b = b1 + (b2 - b1) * f
        let a = a1 + (a2 - a1) * f
        return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
    }
}
