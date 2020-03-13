//
//  BlePeripheral+AdafruitToneGenerator.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 18/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitToneGeneratorServiceUUID = CBUUID(string: "ADAF0C00-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitToneGeneratorCharacteristicUUID = CBUUID(string: "ADAF0C01-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitToneGeneratorVersion = 1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitToneGeneratorCharacteristic: CBCharacteristic?
    }

    private var adafruitToneGeneratorCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitToneGeneratorCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitToneGeneratorCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitToneGeneratorEnable(completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitToneGeneratorVersion, serviceUuid: BlePeripheral.kAdafruitToneGeneratorServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitToneGeneratorCharacteristicUUID) { result in
            switch result {
            case let .success(characteristic):
                self.adafruitToneGeneratorCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitToneGeneratorCharacteristic = nil
                completion?(.failure(error))
            }
        }
    }

    func adafruitToneGeneratorIsEnabled() -> Bool {
        return adafruitToneGeneratorCharacteristic != nil
    }

    func adafruitToneGeneratorDisable() {
        // Clear all specific data
        adafruitToneGeneratorCharacteristic = nil
    }

    func adafruitToneGeneratorStartPlaying(frequency: UInt16, duration: UInt32 = 0) {        // Duration 0 means non-stop
        guard let adafruitToneGeneratorCharacteristic = adafruitToneGeneratorCharacteristic else { return }

        let data = frequency.littleEndian.data + duration.littleEndian.data
        self.write(data: data, for: adafruitToneGeneratorCharacteristic, type: .withResponse)
        //DLog("tone: \(frequency)")
    }
}
