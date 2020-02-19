//
//  UIColor+LightAndDark.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 11/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

// http://stackoverflow.com/questions/11598043/get-slightly-lighter-and-darker-color-from-uicolor

#if os(OSX)

    import Cocoa
    public typealias PXColor = NSColor

#else

    import UIKit
    public typealias PXColor = UIColor

#endif

extension PXColor {

    func lighter(_ amount: CGFloat = 0.25) -> PXColor {
        return hueColorWithBrightnessAmount(1 + amount)
    }

    func darker(_ amount: CGFloat = 0.25) -> PXColor {
        return hueColorWithBrightnessAmount(1 - amount)
    }

    private func hueColorWithBrightnessAmount(_ amount: CGFloat) -> PXColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        #if os(iOS)

            if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
                return PXColor( hue: hue,
                    saturation: saturation,
                    brightness: brightness * amount,
                    alpha: alpha )
            } else {
                return self
            }

        #else

            getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            return PXColor( hue: hue,
                saturation: saturation,
                brightness: brightness * amount,
                alpha: alpha )

        #endif

    }

}
