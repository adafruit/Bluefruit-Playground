//
//  BlePeripheralSimulated.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 14/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

class BlePeripheralSimulated: BlePeripheral {
    // Data
    private var simulatedIdentifier = UUID()
    override var identifier: UUID {
        return simulatedIdentifier
    }

    override var name: String? {
        return "Simulated Peripheral"
    }

    private var simulatedState: CBPeripheralState = .disconnected
    override var state: CBPeripheralState {
        return simulatedState
    }

     // MARK: - Lifecycle
    init() {
        // Mocking CBPeripheral: https://forums.developer.apple.com/thread/29851
        guard let peripheral = ObjectBuilder.createInstance(ofClass: "CBPeripheral") as? CBPeripheral else {
            assertionFailure("Unable to mock CBPeripheral")
            let nilPeripheral: CBPeripheral! = nil          // Just to avoid a compiling error. This will never be executed
            super.init(peripheral: nilPeripheral, advertisementData: nil, rssi: nil)
            return
        }
        peripheral.addObserver(peripheral, forKeyPath: "delegate", options: .new, context: nil)

        let manufacturerDataBytes: [UInt8] = [0x22, 0x08, 0x04, 0x01, 0x00, 0x45, 0x80]     // Adafruit CPB
        let advertisementData = [CBAdvertisementDataManufacturerDataKey: Data(manufacturerDataBytes)]
        super.init(peripheral: peripheral, advertisementData: advertisementData, rssi: 20)
    }

    // MARK: - Discover
    override func discover(serviceUuids: [CBUUID]?, completion: ((Error?) -> Void)?) {
        completion?(nil)
    }

    // MARK: - Connect
    func simulateConnect() {
        simulatedState = .connected
    }

    // MARK: - Disconnect
    override internal func disconnect(with command: BleCommand) {
        // Simulate disconnection
        simulatedState = .disconnected
        BleManagerSimulated.simulated.didDisconnectPeripheral(blePeripheral: self)

        // Finished
        finishedExecutingCommand(error: nil)
    }
}
