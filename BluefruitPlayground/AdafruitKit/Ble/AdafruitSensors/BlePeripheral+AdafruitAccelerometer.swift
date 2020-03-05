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

    static let kAdafruitAccelerometerDefaultPeriod: TimeInterval = 0.1

    struct AccelerometerValue {
        var x: Float
        var y: Float
        var z: Float
    }

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitAccelerometerCharacteristic: CBCharacteristic?
    }

    private var adafruitToneGeneratorEnableAccelerometerCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitAccelerometerCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitAccelerometerCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitAccelerometerEnable(responseHandler: @escaping(Result<(AccelerometerValue, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnable(serviceUuid: BlePeripheral.kAdafruitAccelerometerServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitAccelerometerCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitAccelerometerDefaultPeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                if let acceleration = self.adafruitAccelerometerDataToFloatVector(data) {
                    responseHandler(.success((acceleration, uuid)))
                } else {
                    responseHandler(.failure(PeripheralAdafruitError.invalidResponseData))
                }
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success((version, characteristic)):
                guard version == 1 else {
                    DLog("Warning: adafruitAccelerometerEnable unknown version: \(version)")
                    completion?(.failure(PeripheralAdafruitError.unknownVersion))
                    return
                }

                self.adafruitToneGeneratorEnableAccelerometerCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitToneGeneratorEnableAccelerometerCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitAccelerometerIsEnabled() -> Bool {
        return adafruitToneGeneratorEnableAccelerometerCharacteristic != nil && adafruitToneGeneratorEnableAccelerometerCharacteristic!.isNotifying
    }

    func adafruitAccelerometerDisable() {
        // Clear all specific data
        defer {
            adafruitToneGeneratorEnableAccelerometerCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitToneGeneratorEnableAccelerometerCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitAccelerometerLastValue() -> AccelerometerValue? {
        guard let data = adafruitToneGeneratorEnableAccelerometerCharacteristic?.value else { return nil }
        return adafruitAccelerometerDataToFloatVector(data)
    }

    // MARK: - Utils
    private func adafruitAccelerometerDataToFloatVector(_ data: Data) -> AccelerometerValue? {

        let unitSize = MemoryLayout<Float32>.stride
        var bytes = [Float32](repeating: 0, count: data.count / unitSize)
        (data as NSData).getBytes(&bytes, length: data.count * unitSize)

        guard bytes.count >= 3 else { return nil }

        return AccelerometerValue(x: bytes[0], y: bytes[1], z: bytes[2])
    }
}
