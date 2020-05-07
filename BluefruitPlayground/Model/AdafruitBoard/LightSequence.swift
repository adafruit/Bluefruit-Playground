//
//  LightSequence.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

protocol LightSequenceGenerator {
    var numFrames: Int { get }
    var isCyclic: Bool { get }
    func colorsForFrame(_ frame: Int) -> [[UInt8]]
}

// MARK: - Helper Base class for all LightSequences
class LightSequence {
    var numPixels: Int
    
    var isCyclic: Bool {
        return true
    }
    
    init(numPixels: Int) {
        self.numPixels = numPixels
    }

    // Utils
    static func preprocessColorPalette(colors: [UIColor]) -> [[UInt8]] {
        let colorsBytes = colors.map({ color -> [UInt8] in
            let colorBytes = BlePeripheral.pixelUInt8FromColor(color)
            return colorBytes
            //let colorBytesWithAdjustedBrightness = colorBytes.map{UInt8(CGFloat($0) * brightness)}
            //return colorBytesWithAdjustedBrightness
        })
        return colorsBytes
    }
}

// MARK: - Rotate – seamlessly rotate color array
class RotateLightSequence: LightSequence, LightSequenceGenerator {
    // Constants
    private static let kColors = [#colorLiteral(red: 0.4, green: 0.4, blue: 1, alpha: 1), #colorLiteral(red: 0.1058823529, green: 0.1058823529, blue: 1, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 1, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0.06274509804, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]
    private static let kNumFrames = 10

    // Data
    private var colorsBytes: [[UInt8]]        // in byte format with brightness premultiplied

    // MARK: -
    override init(numPixels: Int) {
        colorsBytes = LightSequence.preprocessColorPalette(colors: RotateLightSequence.kColors)
        super.init(numPixels: numPixels)
    }

    var numFrames: Int {
        return RotateLightSequence.kNumFrames
    }

    func colorsForFrame(_ frame: Int) -> [[UInt8]] {
        return rotate(numPixels: numPixels, colors: colorsBytes, frame: frame)
    }

    private func rotate(numPixels: Int, colors: [[UInt8]], frame: Int) -> [[UInt8]] {
        var lightBytes = [[UInt8]](repeating: [0, 0, 0], count: numPixels)
        for i in 0..<numPixels {
            let colorIndex = (frame + i ) % colors.count
            //DLog("pixel: \(i) color: \(colorIndex)")
            let colorBytes = colors[colorIndex]
            lightBytes[i] = colorBytes
        }

        return lightBytes
    }
}

// MARK: - Pulse – color all LEDs and reverse sequence
class PulseLightSequence: LightSequence, LightSequenceGenerator {
    // Constants
    private static let kColors = [#colorLiteral(red: 0, green: 1, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0.7843137255, blue: 0.06274509804, alpha: 1), #colorLiteral(red: 0, green: 0.7058823529, blue: 0.1254901961, alpha: 1), #colorLiteral(red: 0, green: 0.5882352941, blue: 0.4980392157, alpha: 1), #colorLiteral(red: 0, green: 0.2509803922, blue: 0.4980392157, alpha: 1), #colorLiteral(red: 0, green: 0.1254901961, blue: 0.4980392157, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0.3137254902, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0.2509803922, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0.06274509804, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0.03137254902, alpha: 1)]
    private static let kNumFrames = 10 * 2      // * 2 to take into account reverse animation

    // Data
    private var colorsBytes: [[UInt8]]        // in byte format with brightness premultiplied
    private var reverse = false

    // MARK: -
    override init(numPixels: Int) {
        colorsBytes = LightSequence.preprocessColorPalette(colors: PulseLightSequence.kColors)
        super.init(numPixels: numPixels)
    }

    var numFrames: Int {
        return PulseLightSequence.kNumFrames
    }

    func colorsForFrame(_ frame: Int) -> [[UInt8]] {
        return pulse(numPixels: numPixels, colors: colorsBytes, frame: frame)
    }

    private func pulse(numPixels: Int, colors: [[UInt8]], frame: Int) -> [[UInt8]] {
        var lightBytes = [[UInt8]](repeating: [0, 0, 0], count: numPixels)
        let reverse = frame >= numFrames / 2
        let colorIndex = reverse ? (numFrames - 1) - frame : frame
        for i in 0..<numPixels {
            //DLog("pixel: \(i) color: \(colorIndex)")
            let colorBytes = colors[colorIndex]
            lightBytes[i] = colorBytes
        }

        //DLog("frame \(frame): pixel 0: colorIndex \(colorIndex)")

        return lightBytes
    }
}

// MARK: - Sizzle – pulse even/odd LEDs and reverse
class SizzleLightSequence: LightSequence, LightSequenceGenerator {
    // Constants
    private static let kColors = [#colorLiteral(red: 1, green: 0.3921568627, blue: 0, alpha: 1), #colorLiteral(red: 1, green: 0.3921568627, blue: 0, alpha: 1), #colorLiteral(red: 1, green: 0.1568627451, blue: 0, alpha: 1), #colorLiteral(red: 1, green: 0.1568627451, blue: 0, alpha: 1), #colorLiteral(red: 0.4980392157, green: 0.1254901961, blue: 0, alpha: 1), #colorLiteral(red: 0.4980392157, green: 0.03137254902, blue: 0, alpha: 1), #colorLiteral(red: 0.3137254902, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0.2509803922, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0.06274509804, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]
    private static let kNumFrames = 10 * 2      // * 2 to take into account reverse animation

    // Data
    private var colorsBytes: [[UInt8]]        // in byte format with brightness premultiplied
    private var reverse = false

    // MARK: -
    override init(numPixels: Int) {
        colorsBytes = LightSequence.preprocessColorPalette(colors: SizzleLightSequence.kColors)
        super.init(numPixels: numPixels)
    }

    var numFrames: Int {
        return SizzleLightSequence.kNumFrames
    }

    func colorsForFrame(_ frame: Int) -> [[UInt8]] {
        return sizzle(numPixels: numPixels, colors: colorsBytes, frame: frame)
    }

    private func sizzle(numPixels: Int, colors: [[UInt8]], frame: Int) -> [[UInt8]] {
        var lightBytes = [[UInt8]](repeating: [0, 0, 0], count: numPixels)
        let forwardNumFrames = numFrames / 2
        let reverse = frame >= forwardNumFrames

        let evenIndex = reverse ? (frame % forwardNumFrames) : (forwardNumFrames - 1) - frame
        let oddIndex = reverse ? (numFrames - 1) - frame : frame

        for i in 0..<numPixels {
            //DLog("pixel: \(i) color: \(colorIndex)")
            let colorBytes = colors[i % 2 == 0 ? evenIndex : oddIndex]
            lightBytes[i] = colorBytes
        }

        return lightBytes
    }
}

// MARK: - Sweep – same as rotate, but each side animated alone
class SweepLightSequence: LightSequence, LightSequenceGenerator {
    // Constants
    private static let kColors = [#colorLiteral(red: 1, green: 0, blue: 0.7843137255, alpha: 1), #colorLiteral(red: 0.7843137255, green: 0, blue: 0.4980392157, alpha: 1), #colorLiteral(red: 0.1254901961, green: 0, blue: 0.4980392157, alpha: 1), #colorLiteral(red: 0.06274509804, green: 0, blue: 0.2509803922, alpha: 1), #colorLiteral(red: 0.03137254902, green: 0, blue: 0.1254901961, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0.06274509804, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0.06274509804, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0.03137254902, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]
    private static let kNumFrames = 10

    // Data
    private var colorsBytes: [[UInt8]]        // in byte format with brightness premultiplied

    // MARK: -
    override init(numPixels: Int) {
        colorsBytes = LightSequence.preprocessColorPalette(colors: SweepLightSequence.kColors)
        super.init(numPixels: numPixels)
    }

    var numFrames: Int {
        return SweepLightSequence.kNumFrames
    }

    func colorsForFrame(_ frame: Int) -> [[UInt8]] {
        return sweep(numPixels: numPixels, colors: colorsBytes, frame: frame)
    }

    private func sweep(numPixels: Int, colors: [[UInt8]], frame: Int) -> [[UInt8]] {
        var lightBytes = [[UInt8]](repeating: [0, 0, 0], count: numPixels)
        for i in 0..<numPixels/2 {
            let colorIndex = (frame + i ) % colors.count
            //DLog("pixel: \(i) color: \(colorIndex)")
            lightBytes[i] = colors[colorIndex]                      // left side
            lightBytes[numPixels - 1 - i] = colors[colorIndex]      // right side
        }

        return lightBytes
    }
}

// MARK: - Module Started Animation
class FlashLightSequence: LightSequence, LightSequenceGenerator {
    // Constants
    private static let kNumFrames = 8      // Default frames per second is 10,

    // Data
    private var baseColor: UIColor

    // MARK: -
    init(baseColor: UIColor, numPixels: Int) {
        self.baseColor = baseColor
        super.init(numPixels: numPixels)
    }

    var numFrames: Int {
        return FlashLightSequence.kNumFrames
    }

    override var isCyclic: Bool {
        return false
    }

    func colorsForFrame(_ frame: Int) -> [[UInt8]] {
        return flash(baseColor: baseColor, numPixels: numPixels, frame: frame)
    }

    private func flash(baseColor: UIColor, numPixels: Int, frame: Int) -> [[UInt8]] {
        var lightBytes = [[UInt8]](repeating: [0, 0, 0], count: numPixels)

        let factor = CGFloat(frame) / CGFloat(numFrames)

        let originColor: UIColor
        let endColor: UIColor
        let fraction: CGFloat
        if factor < 0.5 {
            originColor = .clear
            endColor = baseColor
            fraction = factor * 2
        } else {
            originColor = baseColor
            endColor = .clear
            fraction = (factor - 0.5) * 2
        }

        let color = originColor.interpolateRGBColorTo(end: endColor, fraction: fraction)
        //let color = originColor.interpolateHSVColorFrom(end: endColor, fraction: fraction)
        let colorBytes = BlePeripheral.pixelUInt8FromColor(color)

        for i in 0..<numPixels {
            lightBytes[i] = colorBytes
        }

        return lightBytes
    }
}
