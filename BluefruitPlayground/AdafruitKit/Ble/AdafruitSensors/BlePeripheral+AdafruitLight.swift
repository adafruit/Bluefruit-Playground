//
//  BlePeripheral+AdafruitLight.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitLightServiceUUID = CBUUID(string: "ADAF0300-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitLightCharacteristicUUID = CBUUID(string: "ADAF0301-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitLightVersion = 1
    
    static let kAdafruitLightDefaultPeriod: TimeInterval = 0.1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitLightCharacteristic: CBCharacteristic?
    }

    private var adafruitLightCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitLightCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitLightCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitLightEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitLightVersion, serviceUuid: BlePeripheral.kAdafruitLightServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitLightCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitLightDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                let value = self.adafruitLightDataToFloat(data)
                responseHandler(.success((value, uuid)))
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success(characteristic):
                self.adafruitLightCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitLightCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitLightIsEnabled() -> Bool {
        return adafruitLightCharacteristic != nil && adafruitLightCharacteristic!.isNotifying
    }

    func adafruitLightDisable() {
        // Clear all specific data
        defer {
            adafruitLightCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitLightCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitLightLastValue() -> Float? {
        guard let data = adafruitLightCharacteristic?.value else { return nil }
        return adafruitLightDataToFloat(data)
    }

    // MARK: - Utils
    private func adafruitLightDataToFloat(_ data: Data) -> Float {
        return data.toFloatFrom32Bits()
    }
}
