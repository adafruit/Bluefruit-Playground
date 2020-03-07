//
//  NSLayoutConstraint+ChangeMultiplier.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 11/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

// from: https://stackoverflow.com/questions/19593641/can-i-change-multiplier-property-for-nslayoutconstraint/32859742
extension NSLayoutConstraint {
    /**
     Change multiplier constraint
     
     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
     */
    static func setMultiplier(multiplier: CGFloat, constraint: inout NSLayoutConstraint) {

        guard multiplier != 0 else {
            DLog("Warning: multiplier 0 breaks this function")
            return
        }

        NSLayoutConstraint.deactivate([constraint])

        let newConstraint = NSLayoutConstraint(
            item: constraint.firstItem as Any,
            attribute: constraint.firstAttribute,
            relatedBy: constraint.relation,
            toItem: constraint.secondItem,
            attribute: constraint.secondAttribute,
            multiplier: multiplier,
            constant: constraint.constant)

        newConstraint.priority = constraint.priority
        newConstraint.shouldBeArchived = constraint.shouldBeArchived
        newConstraint.identifier = constraint.identifier

        NSLayoutConstraint.activate([newConstraint])
        constraint = newConstraint
    }
}
