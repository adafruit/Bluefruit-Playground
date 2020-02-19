//
//  BlePeripheral+CPBToneGenerator.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 18/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kCPBToneGeneratorServiceUUID = CBUUID(string: "ADAF0C00-C332-42A8-93BD-25E905756CB8")
    private static let kCPBToneGeneratorCharacteristicUUID = CBUUID(string: "ADAF0C01-C332-42A8-93BD-25E905756CB8")

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var cpbToneGeneratorCharacteristic: CBCharacteristic?
    }

    private var cpbToneGeneratorCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.cpbToneGeneratorCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.cpbToneGeneratorCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func cpbToneGeneratorEnable(completion: ((Result<Void, Error>) -> Void)?) {

        self.cpbServiceEnable(serviceUuid: BlePeripheral.kCPBToneGeneratorServiceUUID, mainCharacteristicUuid: BlePeripheral.kCPBToneGeneratorCharacteristicUUID) { result in
            switch result {
            case let .success((version, characteristic)):
                guard version == 1 else {
                    DLog("Warning: cpbToneGeneratorEnable unknown version: \(version)")
                    completion?(.failure(PeripheralCPBError.unknownVersion))
                    return
                }

                self.cpbToneGeneratorCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.cpbToneGeneratorCharacteristic = nil
                completion?(.failure(error))
            }
        }
    }

    func isCpbToneGeneratorEnabled() -> Bool {
        return cpbToneGeneratorCharacteristic != nil
    }

    func cpbToneGeneratorDisable() {
        // Clear all specific data
        cpbToneGeneratorCharacteristic = nil
    }

    func cpbToneGeneratorStartPlaying(frequency: UInt16, duration: UInt32 = 0) {        // Duration 0 means non-stop
        guard let cpbToneGeneratorCharacteristic = cpbToneGeneratorCharacteristic else { return }

        let data = frequency.littleEndian.data + duration.littleEndian.data
        self.write(data: data, for: cpbToneGeneratorCharacteristic, type: .withResponse)
        //DLog("tone: \(frequency)")
    }
}
