//
//  BlePeripheral+AdafruitSoundSensor.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 09/03/2020.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitSoundSensorServiceUUID = CBUUID(string: "ADAF0B00-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitSoundSamplesCharacteristicUUID = CBUUID(string: "ADAF0B01-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitSoundNumberOfChannelsCharacteristicUUID = CBUUID(string: "ADAF0B02-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitSoundSensorVersion = 1
    
    private static let kAdafruitSoundSensorDefaultPeriod: TimeInterval = 0.1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitSoundSensorCharacteristic: CBCharacteristic?
    }

    private var adafruitSoundSensorCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitSoundSensorCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitSoundSensorCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitSoundEnable(responseHandler: @escaping(Result<([UInt16], UUID), Error>) -> Void, completion: ((Result<Int, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitSoundSensorVersion, serviceUuid: BlePeripheral.kAdafruitSoundSensorServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitSoundSamplesCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitSoundSensorDefaultPeriod, responseHandler: { response in
            
            switch response {
            case let .success((data, uuid)):
                let value = self.adafruitSoundDataToSound(data)
                responseHandler(.success((value, uuid)))
                
            case let .failure(error):
                responseHandler(.failure(error))
            }
            
        }, completion: { result in
            switch result {
            case let .success(characteristic):
                self.adafruitSoundSensorCharacteristic = characteristic
                
                self.characteristic(uuid: BlePeripheral.kAdafruitSoundNumberOfChannelsCharacteristicUUID, serviceUuid: BlePeripheral.kAdafruitSoundSensorServiceUUID) { (characteristic, error) in
                    
                    guard error == nil, let characteristic = characteristic, let data = characteristic.value, let numChannels = UInt8(data:data) else {
                        completion?(.failure(PeripheralAdafruitError.invalidCharacteristic))
                        return
                    }
                    
                    completion?(.success(Int(numChannels)))
                }
                
                
            case let .failure(error):
                self.adafruitSoundSensorCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitSoundIsEnabled() -> Bool {
        return adafruitSoundSensorCharacteristic != nil && adafruitSoundSensorCharacteristic!.isNotifying
    }

    func adafruitSoundDisable() {
        // Clear all specific data
        defer {
            adafruitSoundSensorCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitSoundSensorCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitSoundLastValue() -> [UInt16] {
        guard let data = adafruitSoundSensorCharacteristic?.value else { return [] }
        return adafruitSoundDataToSound(data)
    }

    // MARK: - Utils
    private func adafruitSoundDataToSound(_ data: Data) -> [UInt16] {
        guard let components = adafruitDataToUInt16Array(data) else { return [] }
        return components
    }
}
