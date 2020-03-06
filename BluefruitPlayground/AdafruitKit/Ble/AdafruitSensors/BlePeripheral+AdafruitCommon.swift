//
//  BlePeripehral+AdafruitCommon.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Costants
    private static let kAdafruitMeasurementPeriodCharacteristicUUID = CBUUID(string: "ADAF0001-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitMeasurementVersionCharacteristicUUID = CBUUID(string: "ADAF0002-C332-42A8-93BD-25E905756CB8")

    private static let kAdafruitDefaultVersionValue = 1         // Used as default version value if version characteristic cannot be read

    // MARK: - Errors
    enum PeripheralAdafruitError: Error {
        case invalidCharacteristic
        case enableNotifyFailed
        case disableNotifyFailed
        case unknownVersion
        case invalidResponseData
    }

    // MARK: - Service Actions
    func adafruitServiceEnable(serviceUuid: CBUUID, mainCharacteristicUuid: CBUUID, completion: ((Result<(Int, CBCharacteristic), Error>) -> Void)?) {

        self.characteristic(uuid: mainCharacteristicUuid, serviceUuid: serviceUuid) { [unowned self] (characteristic, error) in
            guard let characteristic = characteristic, error == nil else {
                completion?(.failure(error ?? PeripheralAdafruitError.invalidCharacteristic))
                return
            }

            // Check version
            self.adafruitVersion(serviceUuid: serviceUuid) { version in
                completion?(.success((version, characteristic)))
            }
        }
    }

    /**
            - parameters:
                - timePeriod: seconds between measurements. -1 to disable measurements

     */
    func adafruitServiceEnable(serviceUuid: CBUUID, mainCharacteristicUuid: CBUUID, timePeriod: TimeInterval?, responseHandler: @escaping(Result<(Data, UUID), Error>) -> Void, completion: ((Result<(Int, CBCharacteristic), Error>) -> Void)?) {

        self.characteristic(uuid: mainCharacteristicUuid, serviceUuid: serviceUuid) { [unowned self] (characteristic, error) in
            guard let characteristic = characteristic, error == nil else {
                completion?(.failure(error ?? PeripheralAdafruitError.invalidCharacteristic))
                return
            }

            // Check version
            self.adafruitVersion(serviceUuid: serviceUuid) { version in
                // Prepare notification handler
                let notifyHandler: ((Error?) -> Void)? = { [unowned self] error in
                    guard error == nil else {
                        responseHandler(.failure(error!))
                        return
                    }

                    if let data = characteristic.value {
                        responseHandler(.success((data, self.identifier)))
                    }
                }

                // Refresh period handler
                let enableNotificationsHandler = {
                    // Enable notifications
                    if !characteristic.isNotifying {
                        self.enableNotify(for: characteristic, handler: notifyHandler, completion: { error in
                            guard error == nil else {
                                completion?(.failure(error!))
                                return
                            }
                            guard characteristic.isNotifying else {
                                completion?(.failure(PeripheralAdafruitError.enableNotifyFailed))
                                return
                            }

                            completion?(.success((version, characteristic)))

                        })
                    } else {
                        self.updateNotifyHandler(for: characteristic, handler: notifyHandler)
                        completion?(.success((version, characteristic)))
                    }
                }

                // Time period
                if let timePeriod = timePeriod {    // Set timePeriod if not nil
                    self.adafruitSetPeriod(timePeriod, serviceUuid: serviceUuid) { _ in

                        if Config.isDebugEnabled {
                            // Check period
                            self.adafruitPeriod(serviceUuid: serviceUuid) { period in
                                guard period != nil else { DLog("Error setting service period"); return }
                                //DLog("service period: \(period!)")
                            }
                        }

                        enableNotificationsHandler()
                    }
                } else {        // Use default timePeriod
                    enableNotificationsHandler()
                }
            }
        }
    }
    
    func adafruitServiceDisable(serviceUuid: CBUUID, mainCharacteristicUuid: CBUUID, completion: ((Result<Void, Error>) -> Void)?) {
        self.characteristic(uuid: mainCharacteristicUuid, serviceUuid: serviceUuid) { [unowned self] (characteristic, error) in
            guard let characteristic = characteristic, error == nil else {
                completion?(.failure(error ?? PeripheralAdafruitError.invalidCharacteristic))
                return
            }
            
            let kDisablePeriod: TimeInterval = -1       // -1 means taht the updates will be disabled
            self.adafruitSetPeriod(kDisablePeriod, serviceUuid: serviceUuid) { result in
                // Disable notifications
                if characteristic.isNotifying {
                    self.disableNotify(for: characteristic) { error in
                        guard error == nil else {
                            completion?(.failure(error!))
                            return
                        }
                        guard !characteristic.isNotifying else {
                            completion?(.failure(PeripheralAdafruitError.disableNotifyFailed))
                            return
                        }
                        
                        completion?(.success(()))
                    }
                }
                else {
                    completion?(result)
                }
            }
        }
    }

    func adafruitVersion(serviceUuid: CBUUID, completion: @escaping(Int) -> Void) {
        self.characteristic(uuid: BlePeripheral.kAdafruitMeasurementVersionCharacteristicUUID, serviceUuid: serviceUuid) { (characteristic, error) in

            guard error == nil, let characteristic = characteristic, let data = characteristic.value else {
                completion(BlePeripheral.kAdafruitDefaultVersionValue)
                return
            }
            let version = data.toIntFrom32Bits()
            completion(version)
        }
    }

    func adafruitPeriod(serviceUuid: CBUUID, completion: @escaping(TimeInterval?) -> Void) {
        self.characteristic(uuid: BlePeripheral.kAdafruitMeasurementPeriodCharacteristicUUID, serviceUuid: serviceUuid) { (characteristic, error) in

            guard error == nil, let characteristic = characteristic else {
                completion(nil)
                return
            }

            self.readCharacteristic(characteristic) { (data, error) in
                guard error == nil, let data = data as? Data else {
                    completion(nil)
                    return
                }

                let period = TimeInterval(data.toIntFrom32Bits()) / 1000.0
                completion(period)
            }
        }
    }

    /**
        Set measurement period
             
        - parameters:
            - period: seconds between measurements. -1 to disable measurements

      */
    func adafruitSetPeriod(_ period: TimeInterval, serviceUuid: CBUUID, completion: ((Result<Void, Error>) -> Void)?) {

        self.characteristic(uuid: BlePeripheral.kAdafruitMeasurementPeriodCharacteristicUUID, serviceUuid: serviceUuid) { (characteristic, error) in

            guard error == nil, let characteristic = characteristic else {
                DLog("Error: adafruitSetPeriod: \(String(describing: error))")
                return
            }

            let periodMillis = period == -1 ? -1 : Int32(period * 1000)     // -1 means disable measurements. It is a special value
            let data = periodMillis.littleEndian.data
            self.write(data: data, for: characteristic, type: .withResponse) { error in
                guard error == nil else {
                    DLog("Error: adafruitSetPeriod \(error!)")
                    completion?(.failure(error!))
                    return
                }

                completion?(.success(()))
            }
        }
    }
}
