//
//  AdafruitTemperature.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitTemperatureServiceUUID = CBUUID(string: "ADAF0100-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitTemperatureCharacteristicUUID = CBUUID(string: "ADAF0101-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitTemperatureVersion = 1
    
    private static let kAdafruitTemperatureDefaultPeriod: TimeInterval = 0.1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitTemperatureCharacteristic: CBCharacteristic?
    }

    private var adafruitTemperatureCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitTemperatureCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitTemperatureCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitTemperatureEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitTemperatureVersion, serviceUuid: BlePeripheral.kAdafruitTemperatureServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitTemperatureCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitTemperatureDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                let temperature = self.adafruitTemperatureDataToFloat(data)
                responseHandler(.success((temperature, uuid)))
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success(characteristic):
                self.adafruitTemperatureCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitTemperatureCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitTemperatureIsEnabled() -> Bool {
        return adafruitTemperatureCharacteristic != nil && adafruitTemperatureCharacteristic!.isNotifying
    }

    func adafruitTemperatureDisable() {
        // Clear all specific data
        defer {
            adafruitTemperatureCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitTemperatureCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitTemperatureLastValue() -> Float? {
        guard let data = adafruitTemperatureCharacteristic?.value else { return nil }
        return adafruitTemperatureDataToFloat(data)
    }

    // MARK: - Utils
    private func adafruitTemperatureDataToFloat(_ data: Data) -> Float {
        return data.toFloatFrom32Bits()
    }
}
