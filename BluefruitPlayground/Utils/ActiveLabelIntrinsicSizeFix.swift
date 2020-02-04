//
//  ActiveLabelIntrinsicSizeFix.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 30/01/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import ActiveLabel

// Fix as recommended here: https://github.com/optonaut/ActiveLabel.swift/issues/312
extension ActiveLabel {
    open override var intrinsicContentSize: CGSize {
        return super.intrinsicContentSize
    }
}
