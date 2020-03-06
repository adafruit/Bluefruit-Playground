//
//  BlePeripheralSimulated+AdafruitAccelerometer.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitAccelerometerDefaultPeriod: TimeInterval = 0.1
    
    // Structs
    struct AccelerometerValue {
        var x: Float
        var y: Float
        var z: Float
    }
    
    // MARK: - Actions
    func adafruitAccelerometerEnable(responseHandler: @escaping(Result<(AccelerometerValue, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {
        
        completion?(.success(()))
    }
    
    func adafruitAccelerometerIsEnabled() -> Bool {
        return true
    }
    
    func adafruitAccelerometerDisable() {
    }
    
    func adafruitAccelerometerLastValue() -> AccelerometerValue? {
        return AccelerometerValue(x: 0, y: 0, z: 0)
    }
}
