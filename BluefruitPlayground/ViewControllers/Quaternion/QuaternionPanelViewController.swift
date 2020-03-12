//
//  QuaternionPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import SceneKit

class QuaternionPanelViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "QuaternionPanelViewController"

    // UI
    @IBOutlet weak var quaternionTitleLabel: UILabel!
    @IBOutlet weak var quaternionXLabel: UILabel!
    @IBOutlet weak var quaternionYLabel: UILabel!
    @IBOutlet weak var quaternionZLabel: UILabel!
    @IBOutlet weak var quaternionWLabel: UILabel!

    @IBOutlet weak var quaternionEulerAnglesTitleLabel: UILabel!
    @IBOutlet weak var quaternionEulerXLabel: UILabel!
    @IBOutlet weak var quaternionEulerYLabel: UILabel!
    @IBOutlet weak var quaternionEulerZLabel: UILabel!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("quaternion_panel_title")
        quaternionTitleLabel.text = localizationManager.localizedString("quaternion_panel_quaternion_title")
        quaternionEulerAnglesTitleLabel.text = localizationManager.localizedString("quaternion_panel_eulerangles_title")
    }

    func accelerationReceived(quaternion: BlePeripheral.QuaternionValue, eulerAngles: SCNVector3) {

        quaternionXLabel.text = String(format: "%.1f", quaternion.qx)
        quaternionYLabel.text = String(format: "%.1f", quaternion.qy)
        quaternionZLabel.text = String(format: "%.1f", quaternion.qz)
        quaternionWLabel.text = String(format: "%.1f", quaternion.qw)

        let xDeg = eulerAngles.x * 180 / .pi
        let yDeg = eulerAngles.y * 180 / .pi
        let zDeg = eulerAngles.z * 180 / .pi
        
        quaternionEulerXLabel.text = String(format: "%.0f", xDeg)
        quaternionEulerYLabel.text = String(format: "%.0f", yDeg)
        quaternionEulerZLabel.text = String(format: "%.0f", zDeg)
    }
    
    
  
}
