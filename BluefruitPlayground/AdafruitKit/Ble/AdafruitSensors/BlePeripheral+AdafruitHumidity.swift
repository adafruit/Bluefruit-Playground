//
//  BlePeripheral+AdafruitHumidity.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 06/03/2020.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitHumidityServiceUUID = CBUUID(string: "ADAF0700-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitHumidityCharacteristicUUID = CBUUID(string: "ADAF0701-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitHumidityVersion = 1
    
    static let kAdafruitHumidityDefaultPeriod: TimeInterval = 0.1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitHumidityCharacteristic: CBCharacteristic?
    }

    private var adafruitHumidityCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitHumidityCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitHumidityCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitHumidityEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitHumidityVersion, serviceUuid: BlePeripheral.kAdafruitHumidityServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitHumidityCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitHumidityDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                let value = self.adafruitHumidityDataToFloat(data)
                responseHandler(.success((value, uuid)))
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success(characteristic):
                self.adafruitHumidityCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitHumidityCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitHumidityIsEnabled() -> Bool {
        return adafruitHumidityCharacteristic != nil && adafruitHumidityCharacteristic!.isNotifying
    }

    func adafruitHumidityDisable() {
        // Clear all specific data
        defer {
            adafruitHumidityCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitHumidityCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitHumidityLastValue() -> Float? {
        guard let data = adafruitHumidityCharacteristic?.value else { return nil }
        return adafruitHumidityDataToFloat(data)
    }

    // MARK: - Utils
    private func adafruitHumidityDataToFloat(_ data: Data) -> Float {
        return data.toFloatFrom32Bits()
    }
}
