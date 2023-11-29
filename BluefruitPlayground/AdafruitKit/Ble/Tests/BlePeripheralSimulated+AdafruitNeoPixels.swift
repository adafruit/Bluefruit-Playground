//
//  BlePeripheralSimulated+AdafruitNeoPixels.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import CoreBluetooth

extension BlePeripheral {
    // Config
    private static let kAdafruitNeoPixelsServiceNumberOfBitsPerPixel = 3

    // MARK: - Actions
    func adafruitNeoPixelsEnable(completion: ((Result<Void, Error>) -> Void)?) {
        completion?(.success(()))
    }

    func adafruitNeoPixelsIsEnabled() -> Bool {
       return true
    }

    func adafruitNeoPixelsDisable() {
    }

    var adafruitNeoPixelsCount: Int {
        return self.adafruitManufacturerData()?.boardModel?.neoPixelsCount ?? 0
    }

    func adafruitNeoPixelSetAllPixelsColor(_ color: UIColor) {
    }

    func adafruitNeoPixelSetPixelColor(index: Int, color: UIColor) {
    }

    func adafruitNeoPixelSetColor(index: UInt, color: UIColor, pixelMask: [Bool]) {
    }

    // MARK: - Low level actions
    func adafruitNeoPixelsWriteData(offset: UInt16, pixelData: Data) {
    }
    
    static func pixelDataFromColor(_ color: UIColor) -> Data {
        let bytes = pixelUInt8FromColor(color)
        return bytes.data
    }

    static func pixelUInt8FromColor(_ color: UIColor) -> [UInt8] {
        return [UInt8]([0, 0, 0])
    }
}
