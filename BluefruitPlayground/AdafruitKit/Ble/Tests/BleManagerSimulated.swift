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
    
    // MARK: - Scanning
    override func startScan(withServices services: [CBUUID]? = nil) {
        scanningStartTime = CACurrentMediaTime()
        
        // Add simulated peripheral
        let simulatedBlePeripheral = BlePeripheralSimulated()
        peripheralsFound[simulatedBlePeripheral.identifier] = simulatedBlePeripheral
        NotificationCenter.default.post(name: .didDiscoverPeripheral, object: nil, userInfo: [NotificationUserInfoKey.uuid.rawValue: simulatedBlePeripheral.identifier])
    }
    
    override func stopScan() {
    }
    
    // MARK: - Connect
    override func connect(to peripheral: BlePeripheral, timeout: TimeInterval? = nil, shouldNotifyOnConnection: Bool = false, shouldNotifyOnDisconnection: Bool = false, shouldNotifyOnNotification: Bool = false) {
        
        guard let blePeripheral = peripheral as? BlePeripheralSimulated else { return }
        blePeripheral.simulateConnect()
        
        // Send notification
        NotificationCenter.default.post(name: .didConnectToPeripheral, object: nil, userInfo: [NotificationUserInfoKey.uuid.rawValue: peripheral.identifier])
    }
    
    override func reconnecToPeripherals(withIdentifiers identifiers: [UUID], withServices services: [CBUUID], timeout: Double? = nil) -> Bool {
        return false
    }
    
    // MARK: - Disconnect
    override func disconnect(from peripheral: BlePeripheral, waitForQueuedCommands: Bool = false) {
        guard let blePeripheral = peripheral as? BlePeripheralSimulated else { return }
        
        DLog("disconnect")
        NotificationCenter.default.post(name: .willDisconnectFromPeripheral, object: nil, userInfo: [NotificationUserInfoKey.uuid.rawValue: peripheral.identifier])

        if waitForQueuedCommands {
            // Send the disconnection to the command queue, so all the previous command are executed before disconnecting
            if let centralManager = centralManager {
                blePeripheral.disconnect(centralManager: centralManager)
            }
        }
        else {
            didDisconnectPeripheral(blePeripheral: blePeripheral)
        }
    }
    
    func didDisconnectPeripheral(blePeripheral: BlePeripheralSimulated) {
        DLog("didDisconnectPeripheral")

        // Clean
        peripheralsFound[blePeripheral.identifier]?.reset()

        // Notify
        NotificationCenter.default.post(name: .didDisconnectFromPeripheral, object: nil, userInfo: [NotificationUserInfoKey.uuid.rawValue: blePeripheral.identifier])

        // Don't remove the peripheral from the peripheral list (so we can select again the simulated peripheral)
    }
}
