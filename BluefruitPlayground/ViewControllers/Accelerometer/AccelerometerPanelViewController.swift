//
//  AccelerometerPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import SceneKit

class AccelerometerPanelViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "AccelerometerPanelViewController"
    
    // UI
    @IBOutlet weak var accelerometerTitleLabel: UILabel!
    @IBOutlet weak var accelerometerXLabel: UILabel!
    @IBOutlet weak var accelerometerYLabel: UILabel!
    @IBOutlet weak var accelerometerZLabel: UILabel!

    @IBOutlet weak var accelerometerEulerAnglesTitleLabel: UILabel!
    @IBOutlet weak var accelerometerEulerXLabel: UILabel!
    @IBOutlet weak var accelerometerEulerYLabel: UILabel!
    @IBOutlet weak var accelerometerEulerZLabel: UILabel!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("accelerometer_panel_title")
        accelerometerTitleLabel.text = localizationManager.localizedString("accelerometer_panel_accelerometer_title")
        accelerometerEulerAnglesTitleLabel.text = localizationManager.localizedString("accelerometer_panel_eulerangles_title")
    }

    func accelerationReceived(acceleration: BlePeripheral.AccelerometerValue, eulerAngles: SCNVector3) {
        
        accelerometerXLabel.text = String(format: "%.1f", acceleration.x)
        accelerometerYLabel.text = String(format: "%.1f", acceleration.y)
        accelerometerZLabel.text = String(format: "%.1f", acceleration.z)

        let xDeg = eulerAngles.x * 180 / .pi
        let yDeg = eulerAngles.y * 180 / .pi
        let zDeg = eulerAngles.z * 180 / .pi

        accelerometerEulerXLabel.text = String(format: "%.0f", xDeg)
        accelerometerEulerYLabel.text = String(format: "%.0f", yDeg)
        accelerometerEulerZLabel.text = String(format: "%.0f", zDeg)
    }
}
