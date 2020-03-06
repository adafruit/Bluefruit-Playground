//
//  BlePeripheral+AdafruitBarometricPressure.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 06/03/2020.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitBarometricPressureServiceUUID = CBUUID(string: "ADAF0800-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitBarometricPressureCharacteristicUUID = CBUUID(string: "ADAF0801-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitBarometricPressureVersion = 1
    
    private static let kAdafruitBarometricPressureDefaultPeriod: TimeInterval = 0.1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitBarometricPressureCharacteristic: CBCharacteristic?
    }

    private var adafruitBarometricPressureCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitBarometricPressureCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitBarometricPressureCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitBarometricPressureEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitBarometricPressureVersion, serviceUuid: BlePeripheral.kAdafruitBarometricPressureServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitBarometricPressureCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitBarometricPressureDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                let value = self.adafruitBarometricPressureDataToFloat(data)
                responseHandler(.success((value, uuid)))
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success(characteristic):
                self.adafruitBarometricPressureCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitBarometricPressureCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitBarometricPressureIsEnabled() -> Bool {
        return adafruitBarometricPressureCharacteristic != nil && adafruitBarometricPressureCharacteristic!.isNotifying
    }

    func adafruitBarometricPressureDisable() {
        // Clear all specific data
        defer {
            adafruitBarometricPressureCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitBarometricPressureCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitBarometricPressureLastValue() -> Float? {
        guard let data = adafruitBarometricPressureCharacteristic?.value else { return nil }
        return adafruitBarometricPressureDataToFloat(data)
    }

    // MARK: - Utils
    private func adafruitBarometricPressureDataToFloat(_ data: Data) -> Float {
        return data.toFloatFrom32Bits()
    }
}
