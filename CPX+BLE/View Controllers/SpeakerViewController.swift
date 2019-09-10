//
//  SpeakerViewController.swift
//  CPX+BLE
//
//  Created by Trevor B on 9/9/19.
//  Copyright © 2019 Adafruit Industries LLC. All rights reserved.
//

import UIKit

class SpeakerViewController:UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Speaker Page Loaded")
    }
    
    @IBOutlet var FKey: UIButton!
    @IBAction func FKeyAction(_ sender: Any) {
    print("F3 Key was pressed!")
    
    }
    
}

