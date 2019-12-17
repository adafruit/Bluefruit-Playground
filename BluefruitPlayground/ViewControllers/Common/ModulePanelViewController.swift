//
//  ModulePanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 18/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class ModulePanelViewController: UIViewController {

    // UI
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var panelView: UIView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        panelView.layer.cornerRadius = 8
        panelView.layer.masksToBounds = true
    }
}
