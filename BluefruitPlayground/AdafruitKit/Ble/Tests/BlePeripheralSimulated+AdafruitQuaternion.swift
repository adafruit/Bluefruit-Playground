//
//  BlePeripheral+AdafruitQuaternion.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

import CoreBluetooth

extension BlePeripheral {
    // Structs
    struct QuaternionValue {
        var x: Float
        var y: Float
        var z: Float
        var w: Float
    }

    // MARK: - Actions
    func adafruitQuaternionEnable(responseHandler: @escaping(Result<(QuaternionValue, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        completion?(.success(()))
    }

    func adafruitQuaternionIsEnabled() -> Bool {
        return self.adafruitManufacturerData()?.boardModel == .clue_nRF52840
    }

    func adafruitQuaternionDisable() {
        
    }

    func adafruitQuaternionLastValue() -> QuaternionValue? {
        return QuaternionValue(x: 0, y: 0, z: 0, w: 1)
    }

}
