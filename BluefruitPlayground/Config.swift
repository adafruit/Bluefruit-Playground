//
//  Config.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 10/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

struct Config {

    // Scanning
    static let isAutomaticConnectionEnabled = false
    
    
    // Debug-----------------------------------------------------------------------------
    static let isDebugEnabled = _isDebugAssertConfiguration()

    // Fastlane snapshots
    private static let areFastlaneSnapshotsRunning = UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT")
    
    // Bluetooth
    #if SIMULATEBLUETOOTH
    static let isTutorialEnabled = areFastlaneSnapshotsRunning || !isDebugEnabled
    static let isBleUnsupportedWarningEnabled = false
    static let bleManager = BleManagerSimulated.simulated
    #else
    static let isTutorialEnabled = true //!isDebugEnabled
    static let isBleUnsupportedWarningEnabled = true
    static let bleManager = BleManager.shared
    #endif
}
