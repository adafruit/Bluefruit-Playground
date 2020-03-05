//
//  LightSequenceAnimation.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class LightSequenceAnimation {
    // Config
    private static let kIsFrameInterpolationEnabled = true

    // Params
    var speed: Double = 1 // Config.isDebugEnabled ? 0.3 : 1

    // Data
    private var lightSequenceFramesPerSecond: Int
    private var lightSequenceGenerator: LightSequenceGenerator

    private var displaylink: CADisplayLink?

    private var startingTimestamp: TimeInterval = 0
    private var frameHandler: (([[UInt8]]) -> Void)?
    private var stopHandler: (() -> Void)?
    private var repeating: Bool

    // MARK: -
    init(lightSequenceGenerator: LightSequenceGenerator, framesPerSecond: Int, repeating: Bool) {
        self.lightSequenceGenerator = lightSequenceGenerator
        self.lightSequenceFramesPerSecond = framesPerSecond
        self.repeating = repeating
    }

    deinit {
        stop()
    }

    func start(stopHandler:(() -> Void)? = nil, frameHandler: @escaping ([[UInt8]]) -> Void) {
        self.stopHandler = stopHandler
        self.frameHandler = frameHandler

        // Create displayLink if needed
        if displaylink == nil {
            displaylink = CADisplayLink(target: self, selector: #selector(displayLinkStep))
            displaylink!.add(to: .main, forMode: .default)
        }

        guard let displaylink = displaylink else { return }
        displaylink.preferredFramesPerSecond = lightSequenceFramesPerSecond
        startingTimestamp = CACurrentMediaTime()
    }

    func stop() {
        displaylink?.invalidate()
        displaylink = nil
        displaylink?.remove(from: .main, forMode: .default)
        stopHandler?()
    }

    @objc private func displayLinkStep(displaylink: CADisplayLink) {

        let currentTimestamp =  CACurrentMediaTime() - startingTimestamp
        let numFrames = Double(lightSequenceGenerator.numFrames)

        guard repeating || currentTimestamp * numFrames * speed < numFrames else {     // Stop if repeating == false and has displayed all frames
            stop()
            return
        }

        let frame = (currentTimestamp * numFrames * speed).truncatingRemainder(dividingBy: numFrames)

        //DLog("frame: \(frame)")

        var pixelsBytes: [[UInt8]]
        if LightSequenceAnimation.kIsFrameInterpolationEnabled {
            let preFrame = Int(floor(frame))
            let postFrame = lightSequenceGenerator.isCyclic ? Int(ceil(frame)) % lightSequenceGenerator.numFrames : min(Int(ceil(frame)), lightSequenceGenerator.numFrames)
            let postFactor = frame - Double(preFrame)
            let preFactor = 1 - postFactor

            //DLog("pre: \(preFrame), post: \(postFrame), frame: \(frame)")

            let pixelsBytesPre = lightSequenceGenerator.colorsForFrame(preFrame)
            let pixelsBytesPost = lightSequenceGenerator.colorsForFrame(postFrame)

            pixelsBytes = [[UInt8]]()
            for i in 0..<pixelsBytesPre.count {
                let pixelBytesPre = pixelsBytesPre[i]
                let pixelBytesPost = pixelsBytesPost[i]
                let pixelBytes: [UInt8] = [
                    UInt8(Double(pixelBytesPre[0]) * preFactor + Double(pixelBytesPost[0]) * postFactor),
                    UInt8(Double(pixelBytesPre[1]) * preFactor + Double(pixelBytesPost[1]) * postFactor),
                    UInt8(Double(pixelBytesPre[2]) * preFactor + Double(pixelBytesPost[2]) * postFactor)
                ]

                pixelsBytes.append(pixelBytes)
            }
            /*
             DLog("pre: \(preFrame) pixel 0 -> r:\(pixelsBytesPre[0][0]), g:\(pixelsBytesPre[0][1]), b:\(pixelsBytesPre[0][2])")
             DLog("post: \(postFrame) pixel 0 -> r:\(pixelsBytesPost[0][0]), g:\(pixelsBytesPost[0][1]), b:\(pixelsBytesPost[0][2])")
             DLog("frame: \(String(format: "%.2f", frame)) pixel 0 -> r:\(pixelsBytes[0][0]), g:\(pixelsBytes[0][1]), b:\(pixelsBytes[0][2])")
             */
        } else {
            pixelsBytes = lightSequenceGenerator.colorsForFrame(Int(frame))
        }

        frameHandler?(pixelsBytes)
        /*
         if Config.isDebugEnabled {
         let actualFramesPerSecond = 1 / (displaylink.targetTimestamp - displaylink.timestamp)
         DLog("light sequence fps: \(actualFramesPerSecond)")
         }*/

    }
}
