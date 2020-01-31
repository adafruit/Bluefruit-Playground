//
//  BlePeripheral+CPBTemperature.swift
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
           static var cpbTemperatureResponseDataTimer: Timer?
       }
       
       private var cpbTemperatureResponseDataTimer: Timer? {
           get {
               return objc_getAssociatedObject(self, &CustomPropertiesKeys.cpbTemperatureResponseDataTimer) as! Timer?
           }
           set {
               objc_setAssociatedObject(self, &CustomPropertiesKeys.cpbTemperatureResponseDataTimer, newValue, .OBJC_ASSOCIATION_RETAIN)
           }
       }
    
    // MARK: - Actions
    func cpbTemperatureEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {
        
        cpbTemperatureResponseDataTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            guard let temperature = self.cpbTemperatureLastValue() else { return }
            responseHandler(.success((temperature, self.identifier)))
        }
        
        completion?(.success(()))
    }
    
    func isCpbTemperatureEnabled() -> Bool {
        return true
    }
    
    func cpbTemperatureDisable() {
        cpbTemperatureResponseDataTimer?.invalidate()
        cpbTemperatureResponseDataTimer = nil
    }
    
    func cpbTemperatureLastValue() -> Float? {
        let temperature = Float.random(in: 18.5 ..< 19.5)
        return temperature
    }
    
}
