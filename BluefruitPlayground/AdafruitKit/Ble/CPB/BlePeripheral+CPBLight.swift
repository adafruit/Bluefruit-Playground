//
//  BlePeripheral+CPBLight.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kCPBLightServiceUUID = CBUUID(string: "ADAF0300-C332-42A8-93BD-25E905756CB8")
    private static let kCPBLightCharacteristicUUID = CBUUID(string: "ADAF0301-C332-42A8-93BD-25E905756CB8")
    
    private static let kCPBLightDefaultPeriod: TimeInterval = 0.1

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var cpbLightCharacteristic: CBCharacteristic?
    }
    
    private var cpbLightCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.cpbLightCharacteristic) as! CBCharacteristic?
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.cpbLightCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    // MARK: - Actions
    func cpbLightEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {
        
        self.cpbServiceEnable(serviceUuid: BlePeripheral.kCPBLightServiceUUID, mainCharacteristicUuid: BlePeripheral.kCPBLightCharacteristicUUID, timePeriod: BlePeripheral.kCPBLightDefaultPeriod, responseHandler: { response in
            
            switch response {
            case let .success((data, uuid)):
                let light = self.cpbLightDataToFloat(data)
                responseHandler(.success((light, uuid)))
            case let .failure(error):
                responseHandler(.failure(error))
            }
            
        }) { result in
            switch result {
            case let .success((version, characteristic)):
                guard version == 1 else {
                    DLog("Warning: cpbLightEnable unknown version: \(version)")
                    completion?(.failure(PeripheralCPBError.unknownVersion))
                    return
                }
                
                self.cpbLightCharacteristic = characteristic
                completion?(.success(()))
                
            case let .failure(error):
                self.cpbLightCharacteristic = nil
                completion?(.failure(error))
            }
        }
    }
    
    func isCpbLightEnabled() -> Bool {
        return cpbLightCharacteristic != nil && cpbLightCharacteristic!.isNotifying
    }
    
    func cpbLightDisable() {
        // Clear all specific data
        defer {
            cpbLightCharacteristic = nil
        }
        
        // Disable notify
        guard let characteristic = cpbLightCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }
    
    func cpbLightLastValue() -> Float? {
        guard let data = cpbLightCharacteristic?.value else { return nil }
        return cpbLightDataToFloat(data)
    }
    
    // MARK: - Utils
    private func cpbLightDataToFloat(_ data: Data) -> Float {
        return data.toFloatFrom32Bits()
    }
}
