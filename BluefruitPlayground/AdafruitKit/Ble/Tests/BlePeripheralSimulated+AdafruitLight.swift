//
//  BlePeripheralSimulated+AdafruitLight.swift
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
        static var adafruitLightResponseDataTimer: Timer?
    }
    
    private var adafruitLightResponseDataTimer: Timer? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitLightResponseDataTimer) as! Timer?
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitLightResponseDataTimer, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    // MARK: - Actions
    func adafruitLightEnable(responseHandler: @escaping(Result<(Float, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {
        
        adafruitLightResponseDataTimer = Timer.scheduledTimer(withTimeInterval: BlePeripheral.kAdafruitSensorDefaultPeriod, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let value = self.adafruitLightLastValue() else { return }
            responseHandler(.success((value, self.identifier)))
        }
        
        completion?(.success(()))
    }
    
    func adafruitLightIsEnabled() -> Bool {
        return true
    }
    
    func adafruitLightDisable() {
        adafruitLightResponseDataTimer?.invalidate()
        adafruitLightResponseDataTimer = nil
    }
    
    func adafruitLightLastValue() -> Float? {
        let temperature = Float.random(in: 300 ..< 400)
        return temperature
    }
}
