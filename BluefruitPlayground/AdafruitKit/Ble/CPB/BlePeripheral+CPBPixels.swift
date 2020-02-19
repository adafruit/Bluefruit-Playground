//
//  BlePeripheral+CPBPixels.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import CoreBluetooth

extension BlePeripheral {
    // Config
    private static let kPixelsServiceNumberOfBitsPerPixel = 3
    private static let kPixelsServiceNumPixels = 10

    // Constants
    static let kCPBPixelsServiceUUID = CBUUID(string: "ADAF0900-C332-42A8-93BD-25E905756CB8")
    private static let kCPBPixelsDataCharacteristicUUID = CBUUID(string: "ADAF0903-C332-42A8-93BD-25E905756CB8")

    // MARK: - Custom properties
    private struct CustomPropertiesKeys {
        static var cpbPixelsDataCharacteristic: CBCharacteristic?
        static var cpbPixelsDataValue: Data?
    }

    private var cpbPixelsDataCharacteristic: CBCharacteristic? {
        get {
            return objc_getAssociatedObject(self, &CustomPropertiesKeys.cpbPixelsDataCharacteristic) as? CBCharacteristic
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.cpbPixelsDataCharacteristic, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private var cpbPixelsDataValue: Data {
        get {
            if let data = objc_getAssociatedObject(self, &CustomPropertiesKeys.cpbPixelsDataValue) as? Data {
                return data
            } else {      // Initial value
                return Data(repeating: 0, count: BlePeripheral.kPixelsServiceNumPixels * BlePeripheral.kPixelsServiceNumberOfBitsPerPixel)
            }
        }
        set {
            objc_setAssociatedObject(self, &CustomPropertiesKeys.cpbPixelsDataValue, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Actions
    func cpbPixelsEnable(completion: ((Result<Void, Error>) -> Void)?) {

        self.cpbServiceEnable(serviceUuid: BlePeripheral.kCPBPixelsServiceUUID, mainCharacteristicUuid: BlePeripheral.kCPBPixelsDataCharacteristicUUID) { result in
            switch result {
            case let .success((version, characteristic)):
                guard version == 1 else {
                    DLog("Warning: cpbPixelsEnable unknown version: \(version)")
                    completion?(.failure(PeripheralCPBError.unknownVersion))
                    return
                }

                self.cpbPixelsDataCharacteristic = characteristic
                completion?(.success(()))

            case let .failure(error):
                self.cpbPixelsDataCharacteristic = nil
                completion?(.failure(error))
            }
        }
    }

    func isCpbPixelsEnabled() -> Bool {
        return cpbPixelsDataCharacteristic != nil
    }

    func cpbPixelsDisable() {
        // Clear all specific data
        cpbPixelsDataCharacteristic = nil
    }

    func cpbNumPixels() -> Int {
        return BlePeripheral.kPixelsServiceNumPixels
    }

    func cpbPixelSetAllPixelsColor(_ color: UIColor) {
        let colors = [UIColor](repeating: color, count: BlePeripheral.kPixelsServiceNumPixels)
        cpbPixelsWriteData(offset: 0, colors: colors)
    }

    func cpbPixelSetPixelColor(index: Int, color: UIColor) {
        let offset = UInt16(index * BlePeripheral.kPixelsServiceNumberOfBitsPerPixel)
        cpbPixelsWriteData(offset: offset, colors: [color])
    }

    func cpbPixelSetColor(index: UInt, color: UIColor, pixelMask: [Bool]) {
        guard let pixelData = pixelDataFromColorMask(color: color, pixelMask: pixelMask) else {
            DLog("Error neopixelSetColor invalid color data")
            return
        }
        let offset = UInt16(index * UInt(BlePeripheral.kPixelsServiceNumberOfBitsPerPixel))
        cpbPixelsWriteData(offset: offset, pixelData: pixelData)
    }

    // MARK: - Low level actions
    func cpbPixelsWriteData(offset: UInt16, colors: [UIColor]) {
        let pixelData = BlePeripheral.pixelDataFromColors(colors)
        cpbPixelsWriteData(offset: offset, pixelData: pixelData)
    }

    func cpbPixelsWriteData(offset: UInt16, pixelData: Data) {
        guard let cpbPixelsDataCharacteristic = cpbPixelsDataCharacteristic else { return }

        enum Flags: UInt8 {
            case save = 0
            case flush = 1
        }

        let flags = Flags.flush

        let data = offset.littleEndian.data + flags.rawValue.littleEndian.data + pixelData
        // self.write(data: data, for: cpbPixelsDataCharacteristic, type: .withResponse)
        self.write(data: data, for: cpbPixelsDataCharacteristic, type: .withResponse) { [unowned self] error in
            guard error == nil else { DLog("Error cpbPixelsWriteData: \(error!)"); return }

            self.cpbPixelsDataValue = pixelData
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
                let byteOffset = i * BlePeripheral.kPixelsServiceNumberOfBitsPerPixel
                DLog("cpbPixelsDataValue.count: \(cpbPixelsDataValue.count) ")
                if byteOffset < cpbPixelsDataValue.count {
                    existingColorData = Data(cpbPixelsDataValue[byteOffset..<(byteOffset + BlePeripheral.kPixelsServiceNumberOfBitsPerPixel)])
                } else {
                    existingColorData = Data(repeating: 0, count: BlePeripheral.kPixelsServiceNumberOfBitsPerPixel)
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

        return pixelBytes ?? [UInt8](repeating: 0, count: BlePeripheral.kPixelsServiceNumberOfBitsPerPixel)
    }
}
