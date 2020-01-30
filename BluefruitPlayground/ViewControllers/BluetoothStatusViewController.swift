//
//  BluetoothStatusViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 30/01/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothStatusViewController: UIViewController {
    // Constants
    //static let kNavigationControllerIdentifier = "BluetoothStatusNavigationController"
    static let kIdentifier = "BluetoothStatusViewController"
    
    // UI
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var actionView: UIView!
    @IBOutlet weak var actionButton: UIButton!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localization
        actionButton.setTitle(LocalizationManager.shared.localizedString("bluetooth_enable_action").uppercased(), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set text messages depending on current state
        let messageTitle: String
        let message: String
        
        let bluetoothState = Config.bleManager.state
        var isActionHidden: Bool
        switch bluetoothState {
        case .unauthorized:
            messageTitle = "bluetooth_notauthorized"
            message = "bluetooth_notauthorized_detail"
            isActionHidden = false
        case .unsupported:
            messageTitle = "bluetooth_unsupported_le"
            message = "bluetooth_unsupported_le_detail"
            isActionHidden = true
        case .poweredOff:
            messageTitle = "bluetooth_poweredoff"
            message = "bluetooth_poweredoff_detail"
            isActionHidden = false
        default:
            DLog("Error: StatusBluetoothViewController in wrong state: \(bluetoothState)")
            messageTitle = "bluetooth_unsupported"
            message = "bluetooth_unsupported_detail"
            isActionHidden = true
            break
        }
        
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString(messageTitle)
        subtitleLabel.text = localizationManager.localizedString(message)
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
        actionView.isHidden = isActionHidden || settingsUrl == nil || !UIApplication.shared.canOpenURL(settingsUrl!)
    }
    
    
    // MARK: - Actions
    @IBAction func enableBluetooth(_ sender: Any) {
        let bluetoothState = Config.bleManager.state
        
        if bluetoothState == .poweredOff {
            // Force iOS to show the "Turn on bluetooth" alert
            let _ = CBCentralManager(delegate: nil, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        }
        else {
            // Go to settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }
      }
}
