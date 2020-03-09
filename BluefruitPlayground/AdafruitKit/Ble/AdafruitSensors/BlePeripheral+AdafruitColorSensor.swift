//
//  BlePeripheral+AdafruitColorSensor.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 06/03/2020.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitColorSensorServiceUUID = CBUUID(string: "ADAF0A00-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitColorSensorCharacteristicUUID = CBUUID(string: "ADAF0A01-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitColorSensorVersion = 1
    
    private static let kAdafruitColorSensorDefaultPeriod: TimeInterval = 0.1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitColorSensorCharacteristic: CBCharacteristic?
    }

    private var adafruitColorSensorCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitColorSensorCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitColorSensorCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitColorSensorEnable(responseHandler: @escaping(Result<(UIColor, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitColorSensorVersion, serviceUuid: BlePeripheral.kAdafruitColorSensorServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitColorSensorCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitColorSensorDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                if let value = self.adafruitColorSensorDataToColor(data) {
                    responseHandler(.success((value, uuid)))
                }
                else {
                    responseHandler(.failure(PeripheralAdafruitError.invalidResponseData))
                }
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success(characteristic):
                self.adafruitColorSensorCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitColorSensorCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitColorSensorIsEnabled() -> Bool {
        return adafruitColorSensorCharacteristic != nil && adafruitColorSensorCharacteristic!.isNotifying
    }

    func adafruitColorSensorDisable() {
        // Clear all specific data
        defer {
            adafruitColorSensorCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitColorSensorCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitColorSensorLastValue() -> UIColor? {
        guard let data = adafruitColorSensorCharacteristic?.value else { return nil }
        return adafruitColorSensorDataToColor(data)
    }

    // MARK: - Utils
    private func adafruitColorSensorDataToColor(_ data: Data) -> UIColor? {
        guard let components = adafruitDataToUInt16Array(data) else { return nil }
        guard components.count >= 3 else { return nil }
        return UIColor(red: CGFloat(components[0])/CGFloat(UInt16.max), green: CGFloat(components[1])/CGFloat(UInt16.max), blue: CGFloat(components[2])/CGFloat(UInt16.max), alpha: 1)
    }
}
