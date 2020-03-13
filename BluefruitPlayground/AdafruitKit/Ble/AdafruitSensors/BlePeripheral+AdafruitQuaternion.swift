//
//  BlePeripheral+AdafruitQuaternion.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitQuaternionServiceUUID = CBUUID(string: "ADAF0D00-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitQuaternionCharacteristicUUID = CBUUID(string: "ADAF0D01-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitQuaternionCalibrationInCharacteristicUUID = CBUUID(string: "ADAFD002-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitQuaternionCalibrationOutCharacteristicUUID = CBUUID(string: "ADAFD003-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitQuaternionVersion = 1

    // Structs
    struct QuaternionValue {
        var x: Float
        var y: Float
        var z: Float
        var w: Float
    }

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitQuaternionCharacteristic: CBCharacteristic?
    }

    private var adafruitQuaternionCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitQuaternionCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitQuaternionCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitQuaternionEnable(responseHandler: @escaping(Result<(QuaternionValue, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitQuaternionVersion, serviceUuid: BlePeripheral.kAdafruitQuaternionServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitQuaternionCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitSensorDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                if let value = self.adafruitQuaternionDataToQuaternionValue(data) {
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
                self.adafruitQuaternionCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitQuaternionCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitQuaternionIsEnabled() -> Bool {
        return adafruitQuaternionCharacteristic != nil && adafruitQuaternionCharacteristic!.isNotifying
    }

    func adafruitQuaternionDisable() {
        // Clear all specific data
        defer {
            adafruitQuaternionCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitQuaternionCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitQuaternionLastValue() -> QuaternionValue? {
        guard let data = adafruitQuaternionCharacteristic?.value else { return nil }
        return adafruitQuaternionDataToQuaternionValue(data)
    }

    // MARK: - Utils
    private func adafruitQuaternionDataToQuaternionValue(_ data: Data) -> QuaternionValue? {
        
        guard let bytes = adafruitDataToFloatArray(data) else { return nil }
        guard bytes.count >= 4 else { return nil }
//        return QuaternionValue(qx: bytes[0], qy: bytes[1], qz: bytes[2], qw: bytes[3])
        return QuaternionValue(x: bytes[1], y: bytes[2], z: bytes[3], w: bytes[0])
    }
}
