//
//  Config.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 10/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

struct Config {
    
    // Debug-----------------------------------------------------------------------------
    static let isDebugEnabled = _isDebugAssertConfiguration()
    
    // Bluetooth
    #if SIMULATEBLUETOOTH
    static let isTutorialEnabled = !isDebugEnabled
    static let isBleUnsupportedWarningEnabled = false
    static let bleManager = BleManagerSimulated.simulated
    #else
    static let isTutorialEnabled = true //!isDebugEnabled
    static let isBleUnsupportedWarningEnabled = true
    static let bleManager = BleManager.shared
    #endif
}
