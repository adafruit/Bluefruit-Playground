//
//  BlePeripheral+AdafruitHumidity.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 06/03/2020.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // MARK: - Custom properties
     private struct CustomPropertiesKeys {
         static var adafruitHumidityResponseDataTimer: Timer?
     }
     
     private var adafruitHumidityResponseDataTimer: Timer? {
         get {
             return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitHumidityResponseDataTimer) as! Timer?
         }
         set {
             objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitHumidityResponseDataTimer, newValue, .OBJC_ASSOCIATION_RETAIN)
         }
     }
    
    // MARK: - Actions
    func adafruitHumidityEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {
        
        adafruitHumidityResponseDataTimer = Timer.scheduledTimer(withTimeInterval: BlePeripheral.kAdafruitSensorDefaultPeriod, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let value = self.adafruitHumidityLastValue() else { return }
            responseHandler(.success((value, self.identifier)))
        }
        
        completion?(.success(()))
    }

    func adafruitHumidityIsEnabled() -> Bool {
        return self.adafruitManufacturerData()?.boardModel == .clue_nRF52840
    }

    func adafruitHumidityDisable() {
    }

    func adafruitHumidityLastValue() -> Float? {
        return Float.random(in: 28.5 ..< 29.0)
    }
}
