//
//  BlePeripheralSimulated+AdafruitTemperature.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitTemperatureResponseDataTimer: Timer?
    }
    
    private var adafruitTemperatureResponseDataTimer: Timer? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitTemperatureResponseDataTimer) as! Timer?
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitTemperatureResponseDataTimer, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    // MARK: - Actions
    func adafruitTemperatureEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {
        
        adafruitTemperatureResponseDataTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let temperature = self.adafruitTemperatureLastValue() else { return }
            responseHandler(.success((temperature, self.identifier)))
        }
        
        completion?(.success(()))
    }
    
    func adafruitTemperatureIsEnabled() -> Bool {
        return true
    }
    
    func adafruitTemperatureDisable() {
        adafruitTemperatureResponseDataTimer?.invalidate()
        adafruitTemperatureResponseDataTimer = nil
    }
    
    func adafruitTemperatureLastValue() -> Float? {
        let temperature = Float.random(in: 18.5 ..< 19.5)
        return temperature
    }
    
}
