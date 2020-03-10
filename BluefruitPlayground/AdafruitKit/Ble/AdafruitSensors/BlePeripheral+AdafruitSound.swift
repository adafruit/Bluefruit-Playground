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
    
    static let kAdafruitSoundSensorDefaultPeriod: TimeInterval = 0.1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitSoundCharacteristic: CBCharacteristic?
        static var adafruitSoundNumChannels: Int = 0
    }

    private var adafruitSoundCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitSoundCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitSoundCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    private var adafruitSoundNumChannels: Int {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitSoundNumChannels) as? Int ?? 0
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitSoundNumChannels, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    // MARK: - Actions
    func adafruitSoundEnable(responseHandler: @escaping(Result<([[Int16]], UUID), Error>) -> Void, completion: ((Result<Int, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitSoundSensorVersion, serviceUuid: BlePeripheral.kAdafruitSoundSensorServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitSoundSamplesCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitSoundSensorDefaultPeriod, responseHandler: { response in
            
            switch response {
            case let .success((data, uuid)):
                if let value = self.adafruitSoundDataToSound(data) {
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
                self.adafruitSoundCharacteristic = characteristic
                
                // Read number of channels
                self.characteristic(uuid: BlePeripheral.kAdafruitSoundNumberOfChannelsCharacteristicUUID, serviceUuid: BlePeripheral.kAdafruitSoundSensorServiceUUID) { [weak self] (characteristic, error) in
                    
                    guard error == nil, let characteristic = characteristic else {
                        self?.adafruitSoundDisable()        // Error, disable sound // TODO: dont enable until checks have been performed
                        completion?(.failure(PeripheralAdafruitError.invalidCharacteristic))
                        return
                    }
                    
                    self?.readCharacteristic(characteristic) { (result, error) in
                        guard error == nil, let data = result as? Data, data.count >= 1 else {
                            DLog("Error reading numChannels: \(error?.localizedDescription ?? "")")
                            completion?(.failure(PeripheralAdafruitError.invalidResponseData))
                            return
                        }

                        let numChannels = Int(data[0])        // from 0 to 100
                        self?.adafruitSoundNumChannels = numChannels
                        completion?(.success(numChannels))
                    }
                }
                
            case let .failure(error):
                self.adafruitSoundCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitSoundIsEnabled() -> Bool {
        return adafruitSoundCharacteristic != nil && adafruitSoundCharacteristic!.isNotifying && adafruitSoundNumChannels > 0
    }

    func adafruitSoundDisable() {
        // Clear all specific data
        defer {
            adafruitSoundCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitSoundCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitSoundLastValue() -> [[Int16]]? {       // Samples fo reach channel
        guard let data = adafruitSoundCharacteristic?.value else { return nil }
        return adafruitSoundDataToSound(data)
    }

    // MARK: - Utils
    private func adafruitSoundDataToSound(_ data: Data) -> [[Int16]]? {
        guard let samples = adafruitDataToInt16Array(data) else { return nil }
        let numChannels = adafruitSoundNumChannels
        guard numChannels > 0 else { return nil }

        /*
        dump(samples)
        print("----")
 */
        /*
        let channelSamples = [[UInt16]](repeating: [], count: numChannels)

        var currentChannel = 0
        for sample in samples {
            var channel = &channelSamples[currentChannel]
            channel.append(sample)
            currentChannel = (currentChannel + 1) % numChannels
        }
        
        return channelSamples
 */
        return nil
    }
}
