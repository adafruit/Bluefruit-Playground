//
//  OPageTwo.swift
//  CPX+BLE
//
//  Created by Trevor B on 9/25/19.
//  Copyright © 2019 Adafruit Industries LLC. All rights reserved.
//

import UIKit



class OPageTwo : UIViewController {
    

    @IBOutlet var pageTwoGif: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        pageTwoGif.loadGif(name: "Powerup1200")
        
    }
    
    
}
