//
//  ChildViewControllersManagement.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 06/03/2020.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class ChildViewControllersManagement {
    static func addChildViewController(_ viewController: UIViewController, contentView: UIView, parentViewController: UIViewController, belowSubview: UIView? = nil, aboveSubview: UIView? = nil) {

        guard let subview = viewController.view else { return }
        subview.translatesAutoresizingMaskIntoConstraints = false
        if let belowSubview = belowSubview {
            contentView.insertSubview(subview, belowSubview: belowSubview)
        }
        else if let aboveSubview = aboveSubview {
            contentView.insertSubview(subview, aboveSubview: aboveSubview)
        }
        else {
            contentView.addSubview(subview)
        }
        parentViewController.addChild(viewController)         // Note: addchildViewController after addsubview, or it will fail the second time

        let dictionaryOfVariableBindings = ["subview": subview as Any]
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[subview]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: dictionaryOfVariableBindings))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subview]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: dictionaryOfVariableBindings))

        viewController.didMove(toParent: parentViewController)
    }

    static func removeChildViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}
