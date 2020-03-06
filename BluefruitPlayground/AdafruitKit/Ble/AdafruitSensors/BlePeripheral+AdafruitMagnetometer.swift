//
//  BlePeripheral+AdafruitMagnetometer.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 06/03/2020.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitMagnetometerServiceUUID = CBUUID(string: "ADAF0500-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitMagnetometerCharacteristicUUID = CBUUID(string: "ADAF0501-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitMagnetometerVersion = 1

    static let kAdafruitMagnetometerDefaultPeriod: TimeInterval = 0.1

    // Structs
    /// Values in microTesla (μT)
    struct MagnetometerValue {
        var x: Float
        var y: Float
        var z: Float
    }

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitMagnetometerCharacteristic: CBCharacteristic?
    }

    private var adafruitMagnetometerCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitMagnetometerCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitMagnetometerCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitMagnetometerEnable(responseHandler: @escaping(Result<(MagnetometerValue, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitMagnetometerVersion, serviceUuid: BlePeripheral.kAdafruitMagnetometerServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitMagnetometerCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitMagnetometerDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                if let value = self.adafruitMagnetometerDataToMagnetometerValue(data) {
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
                self.adafruitMagnetometerCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitMagnetometerCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitMagnetometerIsEnabled() -> Bool {
        return adafruitMagnetometerCharacteristic != nil && adafruitMagnetometerCharacteristic!.isNotifying
    }

    func adafruitMagnetometerDisable() {
        // Clear all specific data
        defer {
            adafruitMagnetometerCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitMagnetometerCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitMagnetometerLastValue() -> MagnetometerValue? {
        guard let data = adafruitMagnetometerCharacteristic?.value else { return nil }
        return adafruitMagnetometerDataToMagnetometerValue(data)
    }

    // MARK: - Utils
    private func adafruitMagnetometerDataToMagnetometerValue(_ data: Data) -> MagnetometerValue? {
        guard let bytes = adafruitDataToFloatArray(data) else { return nil }
        guard bytes.count >= 3 else { return nil }
        return MagnetometerValue(x: bytes[0], y: bytes[1], z: bytes[2])
    }
}
