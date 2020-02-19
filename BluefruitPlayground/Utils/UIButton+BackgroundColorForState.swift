//
//  UIButton+BackgroundColorForState.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 11/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

// based on https://stackoverflow.com/questions/26600980/how-do-i-set-uibutton-background-color-forstate-uicontrolstate-highlighted-in-s
extension UIButton {

    /// Sets the background color to use for the specified button state.
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        let minimumSize: CGSize = CGSize(width: 1.0, height: 1.0)

        UIGraphicsBeginImageContext(minimumSize)

        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: minimumSize))
        }

        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        //        self.clipsToBounds = true  // not for tvOS. Maybe for iOS is needed
        self.setBackgroundImage(colorImage, for: forState)
    }
}
