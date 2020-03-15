//
//  BlePeripheral+AdafruitBarometricPressure.swift
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
         static var adafruitBarometricPressureResponseDataTimer: Timer?
     }
     
     private var adafruitBarometricPressureResponseDataTimer: Timer? {
         get {
             return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitBarometricPressureResponseDataTimer) as! Timer?
         }
         set {
             objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitBarometricPressureResponseDataTimer, newValue, .OBJC_ASSOCIATION_RETAIN)
         }
     }
    
    // MARK: - Actions
    func adafruitBarometricPressureEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {
        
        adafruitBarometricPressureResponseDataTimer = Timer.scheduledTimer(withTimeInterval: BlePeripheral.kAdafruitSensorDefaultPeriod, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let value = self.adafruitBarometricPressureLastValue() else { return }
            responseHandler(.success((value, self.identifier)))
        }
        
        completion?(.success(()))
    }

    func adafruitBarometricPressureIsEnabled() -> Bool {
        return self.adafruitManufacturerData()?.boardModel == .clue_nRF52840
    }

    func adafruitBarometricPressureDisable() {
    }

    func adafruitBarometricPressureLastValue() -> Float? {
        return Float.random(in: 1190.0 ..< 1191.0)

    }
}
