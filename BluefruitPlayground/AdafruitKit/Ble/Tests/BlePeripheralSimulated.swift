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
        let result: String
        switch model {
        case .circuitPlaygroundBluefruit:
            result = "CPB"
        case .clue_nRF52840:
            result = "CLUE"
        case .feather_nRF52832:
            result = "Feather"
        case .feather_nRF52840_express:
            result = "Feather Express"
        }
        return result
    }

    private var simulatedState: CBPeripheralState = .disconnected
    override var state: CBPeripheralState {
        return simulatedState
    }
    
    private var model: AdafruitManufacturerData.BoardModel

     // MARK: - Lifecycle
    init(model: AdafruitManufacturerData.BoardModel) {
        self.model = model

        // Mocking CBPeripheral: https://forums.developer.apple.com/thread/29851
        guard let peripheral = ObjectBuilder.createInstance(ofClass: "CBPeripheral") as? CBPeripheral else {
            assertionFailure("Unable to mock CBPeripheral")
            let nilPeripheral: CBPeripheral! = nil          // Just to avoid a compiling error. This will never be executed
            super.init(peripheral: nilPeripheral, advertisementData: nil, rssi: nil)
            return
        }
        
        peripheral.addObserver(peripheral, forKeyPath: "delegate", options: .new, context: nil)

        let adafruitManufacturerIdentifier = BlePeripheral.kManufacturerAdafruitIdentifier
        let boardId = model.identifier.first!
        let boardField: [UInt8] = [0x04, 0x01, 0x00] + boardId
        let manufacturerDataBytes: [UInt8] = adafruitManufacturerIdentifier + boardField
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
