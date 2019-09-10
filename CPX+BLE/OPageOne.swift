//
//  OPageOne.swift
//  CPX+BLE
//
//  Created by Trevor B on 8/23/19.
//  Copyright © 2019 Adafruit Industries LLC. All rights reserved.
//

import UIKit

class OPageOne : UIViewController {
    
    @IBOutlet var pageOneGif: UIImageView!
    
override func viewDidLoad() {
    super.viewDidLoad()

    
    pageOneGif.loadGif(name: "NewTest")
    
}


}
