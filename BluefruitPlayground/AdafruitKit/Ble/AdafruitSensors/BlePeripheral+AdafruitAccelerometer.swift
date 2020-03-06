//
//  BlePeripheral+AdafruitAccelerometer.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitAccelerometerServiceUUID = CBUUID(string: "ADAF0200-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitAccelerometerCharacteristicUUID = CBUUID(string: "ADAF0201-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitAccelerometerVersion = 1

    static let kAdafruitAccelerometerDefaultPeriod: TimeInterval = 0.1

    // Structs
    /// Acceleration in m/s²
    struct AccelerometerValue {
        var x: Float
        var y: Float
        var z: Float
    }

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitAccelerometerCharacteristic: CBCharacteristic?
    }

    private var adafruitAccelerometerCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitAccelerometerCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitAccelerometerCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitAccelerometerEnable(responseHandler: @escaping(Result<(AccelerometerValue, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitAccelerometerVersion, serviceUuid: BlePeripheral.kAdafruitAccelerometerServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitAccelerometerCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitAccelerometerDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                if let value = self.adafruitAccelerometerDataToAcceleromterValue(data) {
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
                self.adafruitAccelerometerCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitAccelerometerCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitAccelerometerIsEnabled() -> Bool {
        return adafruitAccelerometerCharacteristic != nil && adafruitAccelerometerCharacteristic!.isNotifying
    }

    func adafruitAccelerometerDisable() {
        // Clear all specific data
        defer {
            adafruitAccelerometerCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitAccelerometerCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitAccelerometerLastValue() -> AccelerometerValue? {
        guard let data = adafruitAccelerometerCharacteristic?.value else { return nil }
        return adafruitAccelerometerDataToAcceleromterValue(data)
    }

    // MARK: - Utils
    private func adafruitAccelerometerDataToAcceleromterValue(_ data: Data) -> AccelerometerValue? {
        
        guard let bytes = adafruitDataToFloatArray(data) else { return nil }
        guard bytes.count >= 3 else { return nil }
        return AccelerometerValue(x: bytes[0], y: bytes[1], z: bytes[2])
    }
}
