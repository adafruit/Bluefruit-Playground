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
    static let kCPBButtonsServiceUUID = CBUUID(string: "ADAF0600-C332-42A8-93BD-25E905756CB8")
    private static let kCPBButtonsCharacteristicUUID = CBUUID(string: "ADAF0601-C332-42A8-93BD-25E905756CB8")

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
        static var cpbButtonsCharacteristic: CBCharacteristic?
    }

    private var cpbButtonsCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.cpbButtonsCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.cpbButtonsCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func cpbButtonsEnable(responseHandler: @escaping(Result<(ButtonsState, UUID), Error>) -> Void, completion: ((Result<Void, Error>) -> Void)?) {

        let timePeriod: TimeInterval = 0        // 0 means that the responseHandler will be called only when there is a change
        self.cpbServiceEnable(serviceUuid: BlePeripheral.kCPBButtonsServiceUUID, mainCharacteristicUuid: BlePeripheral.kCPBButtonsCharacteristicUUID, timePeriod: timePeriod, responseHandler: { response in

            switch response {
            case let .success((data, uuid)):
                let state = self.cpbButtonsDataToStateMask(data)
                responseHandler(.success((state, uuid)))
            case let .failure(error):
                responseHandler(.failure(error))
            }

        }, completion: { result in
            switch result {
            case let .success((version, characteristic)):
                guard version == 1 else {
                    DLog("Warning: cpbButtonsEnable unknown version: \(version)")
                    completion?(.failure(PeripheralCPBError.unknownVersion))
                    return
                }

                self.cpbButtonsCharacteristic = characteristic

                if timePeriod == 0 {    // Read initial state if the timePeriod is 0 (update only when changed)
                    CPBBle.shared.buttonsReadState { response in
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
                self.cpbButtonsCharacteristic = nil
                completion?(.failure(error))
            }
        })
    }

    func isCpbButtonsEnabled() -> Bool {
        return cpbButtonsCharacteristic != nil && cpbButtonsCharacteristic!.isNotifying
    }

    func cpbButtonsDisable() {
        // Clear all specific data
        defer {
            cpbButtonsCharacteristic = nil
        }

        // Disable notify
        guard let characteristic = cpbButtonsCharacteristic, characteristic.isNotifying else { return }
        disableNotify(for: characteristic)
    }

    func cpbButtonsReadState(completion: @escaping(Result<(ButtonsState, UUID), Error>) -> Void) {
        guard let cpbButtonsCharacteristic = cpbButtonsCharacteristic else {
            completion(.failure(PeripheralCPBError.invalidCharacteristic))
            return
        }

        self.readCharacteristic(cpbButtonsCharacteristic) { [weak self] (data, error) in
            guard let self = self else { return }

            guard error == nil, let data = data as? Data else {
                completion(.failure(error ?? PeripheralCPBError.invalidResponseData))
                return
            }

            let state = self.cpbButtonsDataToStateMask(data)
            completion(.success((state, self.identifier)))
        }
    }

    func cpbButtonsLastValue() -> ButtonsState? {
        guard let data = cpbButtonsCharacteristic?.value else { return nil }
        return cpbButtonsDataToStateMask(data)
    }

    // MARK: - Utils
    private func cpbButtonsDataToStateMask(_ data: Data) -> ButtonsState {
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
