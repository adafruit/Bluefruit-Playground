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
    static let kAdafruitSoundSensorMaxAmplitude = 32767
    
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
    func adafruitSoundEnable(responseHandler: @escaping(Result<([Double], UUID), Error>) -> Void, completion: ((Result<Int, Error>) -> Void)?) {

        self.adafruitServiceEnableIfVersion(version: BlePeripheral.kAdafruitSoundSensorVersion, serviceUuid: BlePeripheral.kAdafruitSoundSensorServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitSoundSamplesCharacteristicUUID, timePeriod: BlePeripheral.kAdafruitSoundSensorDefaultPeriod, responseHandler: { [weak self] response in
            
            guard self?.adafruitSoundNumChannels ?? 0 > 0 else { return }      // Ignore received data until sound channels are defined
            // TODO: read sound channels BEFORE enabling notify
            
            switch response {
            case let .success((data, uuid)):
                if let value = self?.adafruitSoundDataToAmplitudePerChannel(data) {
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

    func adafruitSoundLastAmplitudePerChannel() -> [Double]? {       // Samples fo reach channel
        guard let data = adafruitSoundCharacteristic?.value else { return nil }
        return adafruitSoundDataToAmplitudePerChannel(data)
    }
    
    // MARK: - Utils
    /**
     Convert raw data into the amplitude for each channel
     - returns: array with amplitude for each channel measured in decibel relative to full scale (dBFS)
     */
    private func adafruitSoundDataToAmplitudePerChannel(_ data: Data) -> [Double]? {
        guard let samples = adafruitDataToInt16Array(data) else { return nil }
        let numChannels = adafruitSoundNumChannels
        guard numChannels > 0, samples.count >= numChannels else { return nil }

        var samplesSumPerChannel = [Double](repeating: 0, count: numChannels)
        for (index, sample) in samples.enumerated() {
            let channelIndex = index % numChannels
            samplesSumPerChannel[channelIndex] += Double(abs(sample))
        }
        
        let samplesPerChannel = samples.count / numChannels
        var amplitudePerChannel = [Double](repeating: 0, count: numChannels)
        for (index, samplesSum) in samplesSumPerChannel.enumerated() {
            let samplesAvg = samplesSum / Double(samplesPerChannel)
            
            // Calculate amplitude
            // based on: https://devzone.nordicsemi.com/f/nordic-q-a/28248/get-amplitude-db-from-pdm/111560#111560
            let amplitude = 20 * log10(abs(samplesAvg) / Double(BlePeripheral.kAdafruitSoundSensorMaxAmplitude))
            
            // Note:
            //       The base 10 log of -1 is NaN.
            //       The base 10 log of 0 is -Infinity.
                        
            amplitudePerChannel[index] = amplitude
        }
      
        return amplitudePerChannel
      
    }
}
