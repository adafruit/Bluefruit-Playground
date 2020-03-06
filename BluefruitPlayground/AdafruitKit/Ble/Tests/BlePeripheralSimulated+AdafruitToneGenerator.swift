//
//  BlePeripheralSimulated+AdafruitToneGenerator.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 18/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // MARK: - Actions
    func adafruitToneGeneratorEnable(completion: ((Result<Void, Error>) -> Void)?) {
        completion?(.success(()))
    }

    func adafruitToneGeneratorIsEnabled() -> Bool {
        return true
    }

    func adafruitToneGeneratorDisable() {
    }

    func adafruitToneGeneratorStartPlaying(frequency: UInt16, duration: UInt32 = 0) {        // Duration 0 means non-stop
    }
}
