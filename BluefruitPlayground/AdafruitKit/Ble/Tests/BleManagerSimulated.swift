//
//  BleManagerSimulated.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 14/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import CoreBluetooth

class BleManagerSimulated: BleManager {
    
    // Singleton
    static let simulated = BleManagerSimulated()

    // MARK: - Lifecycle
    override init() {
        
    }
    
    override func startScan(withServices services: [CBUUID]? = nil) {
        scanningStartTime = CACurrentMediaTime()
        
        // Add simulated peripheral
        let simulatedBlePeripheral = BlePeripheralSimulated()
        peripheralsFound[simulatedBlePeripheral.identifier] = simulatedBlePeripheral
        NotificationCenter.default.post(name: .didDiscoverPeripheral, object: nil, userInfo: [NotificationUserInfoKey.uuid.rawValue: simulatedBlePeripheral.identifier])
    }
    
    override func stopScan() {
    }
    
    override func connect(to peripheral: BlePeripheral, timeout: TimeInterval? = nil, shouldNotifyOnConnection: Bool = false, shouldNotifyOnDisconnection: Bool = false, shouldNotifyOnNotification: Bool = false) {
        
        // Send notification
        NotificationCenter.default.post(name: .didConnectToPeripheral, object: nil, userInfo: [NotificationUserInfoKey.uuid.rawValue: peripheral.identifier])
    }
    
    override func reconnecToPeripherals(withIdentifiers identifiers: [UUID], withServices services: [CBUUID], timeout: Double? = nil) -> Bool {
        return false
    }
}
