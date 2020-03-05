//
//  BlePeripheral+AdafruitNeoPixels.swift
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
    private static let kAdafruitNeoPixelsServicePixelsCount = 10

    // Constants
    static let kAdafruitNeoPixelsServiceUUID = CBUUID(string: "ADAF0900-C332-42A8-93BD-25E905756CB8")
    private static let kAdafruitNeoPixelsDataCharacteristicUUID = CBUUID(string: "ADAF0903-C332-42A8-93BD-25E905756CB8")

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var adafruitNeoPixelsDataCharacteristic: CBCharacteristic?
        static var adafruitNeoPixelsDataValue: Data?
    }

    private var adafruitNeoPixelsDataCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitNeoPixelsDataCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitNeoPixelsDataCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private var adafruitNeoPixelsDataValue: Data {
        get {
            if let data = objc_getAssociatedObject(self, &CustomPropertiesKeys.adafruitNeoPixelsDataValue) as? Data {
                return data
            } else {      // Initial value
                return Data(repeating: 0, count: BlePeripheral.kAdafruitNeoPixelsServicePixelsCount * BlePeripheral.kAdafruitNeoPixelsServiceNumberOfBitsPerPixel)
            }
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.adafruitNeoPixelsDataValue, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func adafruitNeoPixelsEnable(completion: ((Result<Void, Error>) -> Void)?) {

        self.adafruitServiceEnable(serviceUuid: BlePeripheral.kAdafruitNeoPixelsServiceUUID, mainCharacteristicUuid: BlePeripheral.kAdafruitNeoPixelsDataCharacteristicUUID) { result in
            switch result {
            case let .success((version, characteristic)):
                guard version == 1 else {
                    DLog("Warning: adafruitNeoPixelsEnable unknown version: \(version)")
                    completion?(.failure(PeripheralAdafruitError.unknownVersion))
                    return
                }

                self.adafruitNeoPixelsDataCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.adafruitNeoPixelsDataCharacteristic = nil
                completion?(.failure(error))
            }
        }
    }

    func adafruitNeoPixelsIsEnabled() -> Bool {
        return adafruitNeoPixelsDataCharacteristic != nil
    }

    func adafruitNeoPixelsDisable() {
        // Clear all specific data
        adafruitNeoPixelsDataCharacteristic = nil
    }

    func adafruitNeoPixelsCount() -> Int {
        return BlePeripheral.kAdafruitNeoPixelsServicePixelsCount
    }

    func adafruitNeoPixelSetAllPixelsColor(_ color: UIColor) {
        let colors = [UIColor](repeating: color, count: BlePeripheral.kAdafruitNeoPixelsServicePixelsCount)
        adafruitNeoPixelsWriteData(offset: 0, colors: colors)
    }

    func adafruitNeoPixelSetPixelColor(index: Int, color: UIColor) {
        let offset = UInt16(index * BlePeripheral.kAdafruitNeoPixelsServiceNumberOfBitsPerPixel)
        adafruitNeoPixelsWriteData(offset: offset, colors: [color])
    }

    func adafruitNeoPixelSetColor(index: UInt, color: UIColor, pixelMask: [Bool]) {
        guard let pixelData = pixelDataFromColorMask(color: color, pixelMask: pixelMask) else {
            DLog("Error neopixelSetColor invalid color data")
            return
        }
        let offset = UInt16(index * UInt(BlePeripheral.kAdafruitNeoPixelsServiceNumberOfBitsPerPixel))
        adafruitNeoPixelsWriteData(offset: offset, pixelData: pixelData)
    }

    // MARK: - Low level actions
    func adafruitNeoPixelsWriteData(offset: UInt16, colors: [UIColor]) {
        let pixelData = BlePeripheral.pixelDataFromColors(colors)
        adafruitNeoPixelsWriteData(offset: offset, pixelData: pixelData)
    }

    func adafruitNeoPixelsWriteData(offset: UInt16, pixelData: Data) {
        guard let adafruitNeoPixelsDataCharacteristic = adafruitNeoPixelsDataCharacteristic else { return }

        enum Flags: UInt8 {
            case save = 0
            case flush = 1
        }

        let flags = Flags.flush

        let data = offset.littleEndian.data + flags.rawValue.littleEndian.data + pixelData
        // self.write(data: data, for: cpbPixelsDataCharacteristic, type: .withResponse)
        self.write(data: data, for: adafruitNeoPixelsDataCharacteristic, type: .withResponse) { [unowned self] error in
            guard error == nil else { DLog("Error adafruitNeoPixelsWriteData: \(error!)"); return }

            self.adafruitNeoPixelsDataValue = pixelData
        }
    }

    // MARK: - Utils
    private func pixelDataFromColorMask(color: UIColor, pixelMask: [Bool]) -> Data? {
        let colorData = BlePeripheral.pixelDataFromColor(color)

        var pixelData = Data()
        for (i, mask) in pixelMask.enumerated() {
            if mask {   // overwrite color
                pixelData += colorData
            } else {      // use current color
                let existingColorData: Data
                let byteOffset = i * BlePeripheral.kAdafruitNeoPixelsServiceNumberOfBitsPerPixel
                DLog("adafruitNeoPixelsDataValue.count: \(adafruitNeoPixelsDataValue.count) ")
                if byteOffset < adafruitNeoPixelsDataValue.count {
                    existingColorData = Data(adafruitNeoPixelsDataValue[byteOffset..<(byteOffset + BlePeripheral.kAdafruitNeoPixelsServiceNumberOfBitsPerPixel)])
                } else {
                    existingColorData = Data(repeating: 0, count: BlePeripheral.kAdafruitNeoPixelsServiceNumberOfBitsPerPixel)
                }
                pixelData += existingColorData
            }
        }

        return pixelData
    }

    private static func pixelDataFromColors(_ colors: [UIColor]) -> Data {
        var pixelData = Data()

        for color in colors {
            pixelData += pixelDataFromColor(color)
        }

        return pixelData
    }

    static func pixelDataFromColor(_ color: UIColor) -> Data {
        let bytes = pixelUInt8FromColor(color)
        return bytes.data
    }

    static func pixelUInt8FromColor(_ color: UIColor) -> [UInt8] {
        var pixelBytes: [UInt8]?

        let cgColor = color.cgColor
        let numComponents = cgColor.numberOfComponents
        if let components = cgColor.components {
            if numComponents == 2 {
                let white = UInt8(components[0] * 255)
                //let alpha = UInt8(components[1] * 255)

                pixelBytes = [white, white, white]
            } else if numComponents == 4 {

                let r = UInt8(components[0] * 255)
                let g = UInt8(components[1] * 255)
                let b = UInt8(components[2] * 255)
                //let alpha = UInt8(components[3] * 255)

                pixelBytes = [g, r, b]
            } else {
                DLog("Error converting color (number of components is: \(numComponents))")
            }
        }

        return pixelBytes ?? [UInt8](repeating: 0, count: BlePeripheral.kAdafruitNeoPixelsServiceNumberOfBitsPerPixel)
    }
}
