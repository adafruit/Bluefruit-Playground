//
//  UIView+AllSubviewsWithClass.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

// from: https://stackoverflow.com/questions/32301336/swift-recursively-cycle-through-all-subviews-to-find-a-specific-class-and-appen
// usage: let allLabels = simpleView.getAllSubviewsWithClass() as [UILabel]
extension UIView {
    class func getAllSubviewsWithClass<T: UIView>(view: UIView, tag: Int? = nil) -> [T] {
        return view.subviews.flatMap { subView -> [T] in
            var result = getAllSubviewsWithClass(view: subView, tag: tag) as [T]
            if let view = subView as? T, tag == nil || view.tag == tag {
                result.append(view)
            }
            return result
        }
    }
    
    // If the tag parameter is specified, the subviews have to match the tag
    func getAllSubviewsWithClass<T: UIView>(tag: Int? = nil) -> [T] {
        return UIView.getAllSubviewsWithClass(view: self, tag: tag) as [T]
    }
}
