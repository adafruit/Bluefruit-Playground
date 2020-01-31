//
//  PanelInsetView.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 27/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class PanelInsetView: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        self.layer.borderWidth = 1 / UIScreen.main.scale
    }
}
