//
//  OPageThree.swift
//  CPX+BLE
//
//  Created by Trevor B on 9/25/19.
//  Copyright © 2019 Adafruit Industries LLC. All rights reserved.
//

import UIKit


class OPageThree : UIViewController {
    
    
    @IBOutlet var pageThreeGif: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        pageThreeGif.loadGif(name: "Discover")
        
    }
    
    
}
