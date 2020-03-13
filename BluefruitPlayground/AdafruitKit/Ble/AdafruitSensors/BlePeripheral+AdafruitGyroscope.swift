//
//  BlePeripheral+AdafruitGyroscope.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 06/03/2020.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitGyroscopeServiceUUID = CBUUID(string: "ADAF0400-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitGyroscopeCharacteristicUUID = CBUUID(string: "ADAF0401-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitGyroscopeVersion = 1

    // Structs
    /// Values in rad/s
    struct GyroscopeValue {
        var x: Float
        var y: Float
        var z: Float
    }

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitGyroscopeCharacteristic: CBCharacteristic?
    }

    private var adafruitGyroscopeCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitGyroscopeCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitGyroscopeCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitGyroscopeEnable(responseHandler: @escaping(Result<(GyroscopeValue, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitGyroscopeVersion, serviceUuid: BlePeripheral.kAdafruitGyroscopeServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitGyroscopeCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitSensorDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                if let value = self.adafruitGyroscopeDataToGyroscopeValue(data) {
                    responseHandler(.success((value, uuid)))
                } else {
                    responseHandler(.failure(PeripheralAdafruitError.invalidResponseData))
                }
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success(characteristic):
                self.adafruitGyroscopeCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitGyroscopeCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitGyroscopeIsEnabled() -> Bool {
        return adafruitGyroscopeCharacteristic != nil && adafruitGyroscopeCharacteristic!.isNotifying
    }

    func adafruitGyroscopeDisable() {
        // Clear all specific data
        defer {
            adafruitGyroscopeCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitGyroscopeCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitGyroscopeLastValue() -> GyroscopeValue? {
        guard let data = adafruitGyroscopeCharacteristic?.value else { return nil }
        return adafruitGyroscopeDataToGyroscopeValue(data)
    }

    // MARK: - Utils
    private func adafruitGyroscopeDataToGyroscopeValue(_ data: Data) -> GyroscopeValue? {
        guard let bytes = adafruitDataToFloatArray(data) else { return nil }
        guard bytes.count >= 3 else { return nil }
        return GyroscopeValue(x: bytes[0], y: bytes[1], z: bytes[2])
    }
}
