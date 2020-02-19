//
//  BlePeripheral+CPBAccelerometer.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kCPBAccelerometerServiceUUID = CBUUID(string: "ADAF0200-C332-42A8-93BD-25E905756CB8")
    private static let kCPBAccelerometerCharacteristicUUID = CBUUID(string: "ADAF0201-C332-42A8-93BD-25E905756CB8")

    static let kCPBAccelerometerDefaultPeriod: TimeInterval = 0.1

    struct AccelerometerValue {
        var x: Float
        var y: Float
        var z: Float
    }

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var cpbAccelerometerCharacteristic: CBCharacteristic?
    }

    private var cpbAccelerometerCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.cpbAccelerometerCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.cpbAccelerometerCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func cpbAccelerometerEnable(responseHandler: @escaping(Result<(AccelerometerValue, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.cpbServiceEnable(serviceUuid: BlePeripheral.kCPBAccelerometerServiceUUID, mainCharacteristicUuid: BlePeripheral.kCPBAccelerometerCharacteristicUUID, timePeriod: BlePeripheral.kCPBAccelerometerDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                if let acceleration = self.cpbAccelerometerDataToFloatVector(data) {
                    responseHandler(.success((acceleration, uuid)))
                } else {
                    responseHandler(.failure(PeripheralCPBError.invalidResponseData))
                }
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success((version, characteristic)):
                guard version == 1 else {
                    DLog("Warning: cpbAccelerometerEnable unknown version: \(version)")
                    completion?(.failure(PeripheralCPBError.unknownVersion))
                    return
                }

                self.cpbAccelerometerCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.cpbAccelerometerCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func isCpbAccelerometerEnabled() -> Bool {
        return cpbAccelerometerCharacteristic != nil && cpbAccelerometerCharacteristic!.isNotifying
    }

    func cpbAccelerometerDisable() {
        // Clear all specific data
        defer {
            cpbAccelerometerCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = cpbAccelerometerCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func cpbAccelerometerLastValue() -> AccelerometerValue? {
        guard let data = cpbAccelerometerCharacteristic?.value else { return nil }
        return cpbAccelerometerDataToFloatVector(data)
    }

    // MARK: - Utils
    private func cpbAccelerometerDataToFloatVector(_ data: Data) -> AccelerometerValue? {

        let unitSize = MemoryLayout<Float32>.stride
        var bytes = [Float32](repeating: 0, count: data.count / unitSize)
        (data as NSData).getBytes(&bytes, length: data.count * unitSize)

        guard bytes.count >= 3 else { return nil }

        return AccelerometerValue(x: bytes[0], y: bytes[1], z: bytes[2])
    }
}
