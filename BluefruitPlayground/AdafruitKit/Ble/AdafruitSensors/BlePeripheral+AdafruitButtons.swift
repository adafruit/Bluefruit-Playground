//
//  BlePeripheral+AdafruitButtons.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 15/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    static let kAdafruitButtonsServiceUUID = CBUUID(string: "ADAF0600-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitButtonsCharacteristicUUID = CBUUID(string: "ADAF0601-C332-42A8-93BD-25E905756CB8")

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

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitButtonsCharacteristic: CBCharacteristic?
    }

    private var adafruitButtonsCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitButtonsCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitButtonsCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitButtonsEnable(responseHandler: @escaping(Result<(ButtonsState, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        let timePeriod: TimeInterval = 0        // 0 means that the responseHandler will be called only when there is a change
        self.adafruitServiceEnable(serviceUuid: BlePeripheral.kAdafruitButtonsServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitButtonsCharacteristicUUID, timePeriod: timePeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                let state = self.adafruitButtonsDataToStateMask(data)
                responseHandler(.success((state, uuid)))
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success((version, characteristic)):
                guard version == 1 else {
                    DLog("Warning: adafruitButtonsEnable unknown version: \(version)")
                    completion?(.failure(PeripheralAdafruitError.unknownVersion))
                    return
                }

                self.adafruitButtonsCharacteristic = characteristic

                if timePeriod == 0 {    // Read initial state if the timePeriod is 0 (update only when changed)
                    self.adafruitButtonsReadState { response in
                        switch response {
                        case .success:
                            completion?(.success(()))
                        case .failure(let error):
                            DLog("Error receiving initial button state data: \(error)")
                            completion?(.failure(error))
                        }
                    }
                } else {
                    completion?(.success(()))
                }

            case let .failure(error):
                self.adafruitButtonsCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func adafruitButtonsIsEnabled() -> Bool {
        return adafruitButtonsCharacteristic != nil && adafruitButtonsCharacteristic!.isNotifying
    }

    func adafruitButtonsDisable() {
        // Clear all specific data
        defer {
            adafruitButtonsCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = adafruitButtonsCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func adafruitButtonsReadState(completion: @escaping(Result<(ButtonsState, UUID), Error>) -> Void) {
        guard let adafruitButtonsCharacteristic = adafruitButtonsCharacteristic else {
            completion(.failure(PeripheralAdafruitError.invalidCharacteristic))
            return
        }

        self.readCharacteristic(adafruitButtonsCharacteristic) { [weak self] (data, error) in
            guard let self = self else { return }

            guard error == nil, let data = data as? Data else {
                completion(.failure(error ?? PeripheralAdafruitError.invalidResponseData))
                return
            }

            let state = self.adafruitButtonsDataToStateMask(data)
            completion(.success((state, self.identifier)))
        }
    }

    func adafruitButtonsLastValue() -> ButtonsState? {
        guard let data = adafruitButtonsCharacteristic?.value else { return nil }
        return adafruitButtonsDataToStateMask(data)
    }

    // MARK: - Utils
    private func adafruitButtonsDataToStateMask(_ data: Data) -> ButtonsState {
        let stateMask = data.toInt32From32Bits()

        let slideSwitchBit = stateMask & 0b1
        let slideSwitchState = SlideSwitchState(rawValue: slideSwitchBit)!

        let buttonABit = ( stateMask >> 1 ) & 0b1
        let buttonAState = ButtonState(rawValue: buttonABit)!

        let buttonBBit = ( stateMask >> 2 ) & 0b1
        let buttonBState = ButtonState(rawValue: buttonBBit)!

        return ButtonsState(slideSwitch: slideSwitchState, buttonA: buttonAState, buttonB: buttonBState)
    }
}
