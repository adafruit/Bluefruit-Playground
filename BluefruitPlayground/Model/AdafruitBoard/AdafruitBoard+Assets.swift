//
//  AdafruitBoard+Assets.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/03/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import Foundation

extension AdafruitBoard {
    
    var asset3DFileName: String? {
        var filename: String?
        if let model = self.model {
            switch model {
            case .circuitPlaygroundBluefruit:
                filename = "cpb.scn"
            case .clue_nRF52840:
                filename = "clue.scn"
            default:
                filename = nil
            }
        }
        
        return filename
    }
}
