//
//  PeripheralList.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 11/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

class PeripheralList {
    // Data
    private(set) var bleManager: BleManager
    private var peripherals = [BlePeripheral]()
    private var cachedFilteredPeripherals: [BlePeripheral] = []

    // MARK: - Lifecycle
    init(bleManager: BleManager) {
        self.bleManager = bleManager
    }

    // MARK: - Actions
    func filteredPeripherals(forceUpdate: Bool) -> [BlePeripheral] {
        if forceUpdate {
            cachedFilteredPeripherals = calculateFilteredPeripherals()
        }
        return cachedFilteredPeripherals
    }

    func clear() {
        peripherals.removeAll()
    }

    private func calculateFilteredPeripherals() -> [BlePeripheral] {
        let peripherals = bleManager.peripherals().filter({$0.isManufacturerAdafruit()}).sorted{ (p0, p1) -> Bool in
             return (p0.rssi ?? -127) > (p1.rssi ?? -127)
        }
        return peripherals

        //return peripherals.filter({$0.rssi ?? -127 > -55})
    }
}
