//
//  BlePeripheral+ManufacturerAdafruit.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 10/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BlePeripheral {
    // Constants
    private static let kManufacturerAdafruitIdentifier: [UInt8] = [0x22, 0x08]
    
    func isManufacturerAdafruit() -> Bool {
        guard let manufacturerIdentifier = advertisement.manufacturerIdentifier else { return false }
        
        let manufacturerIdentifierBytes = [UInt8](manufacturerIdentifier)
        //DLog("\(name) manufacturer: \(advertisement.manufacturerString)")
        return manufacturerIdentifierBytes == BlePeripheral.kManufacturerAdafruitIdentifier
    }
}
