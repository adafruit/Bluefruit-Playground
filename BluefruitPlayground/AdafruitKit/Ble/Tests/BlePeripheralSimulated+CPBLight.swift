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
    // MARK: - Actions
    func cpbLightEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        completion?(.success(()))
    }

    func isCpbLightEnabled() -> Bool {
        return true
    }

    func cpbLightDisable() {
    }

    func cpbLightLastValue() -> Float? {
        let temperature = Float.random(in: 300 ..< 400)
        return temperature
    }
 }
