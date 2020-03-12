//
//  AdafruitBoard+Assets.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/03/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit
import SceneKit

extension AdafruitBoard {
    
    var assetScene: SCNScene? {
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
        
        let scene: SCNScene?
        if let filename = filename {
            scene = SCNScene(named: filename)
            scene?.background.contents = UIColor.clear
        }
        else {
            scene = nil
        }
                
        return scene
    }
    
    var assetFrontImage: UIImage? {
        var name: String?
        if let model = self.model {
            switch model {
            case .circuitPlaygroundBluefruit:
                name = "board_cpb"
            case .clue_nRF52840:
                name = "board_clue_front"
            default:
                name = nil
            }
        }
        
        return name == nil ? nil : UIImage(named: name!)
    }
}
