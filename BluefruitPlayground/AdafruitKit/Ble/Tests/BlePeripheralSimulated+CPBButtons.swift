//
//  BlePeripheral+CPBButtons.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 15/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    
    enum SlideSwitchState: Int32 {
        case right = 0
        case left = 1
    }
    
    enum ButtonState: Int32 {
        case released = 0
        case pressed = 1
    }
    
    struct ButtonsState {
        var slideSwitch: SlideSwitchState
        var buttonA: ButtonState
        var buttonB: ButtonState
    }
    
    
    // MARK: - Actions
    func cpbButtonsEnable(responseHandler: @escaping(Result<(ButtonsState, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {
         completion?(.success(()))
    }
    
    func isCpbButtonsEnabled() -> Bool {
        return true
    }
    
    func cpbButtonsDisable() {
    }
    
    func cpbButtonsLastValue() -> ButtonsState? {
        return ButtonsState(slideSwitch: .left, buttonA: .pressed, buttonB: .released)
        
    }
}
