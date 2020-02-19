//
//  BlePeripheral+CPBTemperature.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kCPBTemperatureServiceUUID = CBUUID(string: "ADAF0100-C332-42A8-93BD-25E905756CB8")
    private static let kCPBTemperatureCharacteristicUUID = CBUUID(string: "ADAF0101-C332-42A8-93BD-25E905756CB8")

    private static let kCPBTemperatureDefaultPeriod: TimeInterval = 0.1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var cpbTemperatureCharacteristic: CBCharacteristic?
    }

    private var cpbTemperatureCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.cpbTemperatureCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.cpbTemperatureCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func cpbTemperatureEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.cpbServiceEnable(serviceUuid: BlePeripheral.kCPBTemperatureServiceUUID, mainCharacteristicUuid: BlePeripheral.kCPBTemperatureCharacteristicUUID, timePeriod: BlePeripheral.kCPBTemperatureDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                let temperature = self.cpbTemperatureDataToFloat(data)
                responseHandler(.success((temperature, uuid)))
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success((version, characteristic)):
                guard version == 1 else {
                    DLog("Warning: cpbTemperatureEnable unknown version: \(version)")
                    completion?(.failure(PeripheralCPBError.unknownVersion))
                    return
                }

                self.cpbTemperatureCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.cpbTemperatureCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func isCpbTemperatureEnabled() -> Bool {
        return cpbTemperatureCharacteristic != nil && cpbTemperatureCharacteristic!.isNotifying
    }

    func cpbTemperatureDisable() {
        // Clear all specific data
        defer {
            cpbTemperatureCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = cpbTemperatureCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func cpbTemperatureLastValue() -> Float? {
        guard let data = cpbTemperatureCharacteristic?.value else { return nil }
        return cpbTemperatureDataToFloat(data)
    }

    // MARK: - Utils
    private func cpbTemperatureDataToFloat(_ data: Data) -> Float {
        return data.toFloatFrom32Bits()
    }
}
