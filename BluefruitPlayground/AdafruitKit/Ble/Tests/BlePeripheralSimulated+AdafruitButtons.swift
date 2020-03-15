//
//  BlePeripheralSimulated+AdafruitButtons.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 15/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
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
    func adafruitButtonsEnable(responseHandler: @escaping(Result<(ButtonsState, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {
        completion?(.success(()))
    }
    
    func adafruitButtonsIsEnabled() -> Bool {
        return true
    }
    
    func adafruitButtonsDisable() {
    }
    
    func adafruitButtonsReadState(completion: @escaping(Result<(ButtonsState, UUID), Error>) -> Void) {
        guard let state = adafruitButtonsLastValue() else {
            completion(.failure(PeripheralAdafruitError.invalidResponseData))
            return
        }
        completion(.success((state, self.identifier)))
    }
    
    func adafruitButtonsLastValue() -> ButtonsState? {
        return ButtonsState(slideSwitch: .left, buttonA: .pressed, buttonB: .released)
        
    }
}
