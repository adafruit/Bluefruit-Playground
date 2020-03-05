//
//  PixelsPreviewViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class PixelsPreviewViewController: UIViewController {
    // Constant
    private static let kNumNeopixels = 10
    private static let kButtonStartTag = 100

    // UI
    @IBOutlet weak var neopixelsContainerView: UIView!
    @IBOutlet weak var neopixelsContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var neopixelViewWidthConstraint: NSLayoutConstraint!

    // Params
    var tag = 0
    var speed: Double = 1 {
        didSet {
            lightSequenceAnimation?.speed = speed
        }
    }

    // Data
    private var currentScale: CGFloat = 0
    private var lightSequenceAnimation: LightSequenceAnimation?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make neopixels round
        for neopixelView in neopixelsContainerView.subviews {
            neopixelView.layer.cornerRadius = neopixelViewWidthConstraint.constant / 2
            neopixelView.layer.masksToBounds = true
            //neopixelView.layer.borderColor = UIColor.yellow.cgColor
        }

        // Init neopixels color
        for neopixelView in self.neopixelsContainerView.subviews {
            neopixelView.backgroundColor = .clear
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let lightSequenceGenerator = lightSequenceGeneratorForTag(self.tag) else { return }

        lightSequenceAnimation = LightSequenceAnimation(lightSequenceGenerator: lightSequenceGenerator, framesPerSecond: 10, repeating: true)
        lightSequenceAnimation!.speed = speed
        lightSequenceAnimation!.start { [weak self] pixelsBytes in
            guard let self = self else { return }

            let pixelColors = pixelsBytes.map { UIColor(red: CGFloat($0[1])/255.0, green: CGFloat($0[0])/255.0, blue: CGFloat($0[2])/255.0, alpha: 1.0) }

            // Update UI colors (on main thread)
            DispatchQueue.main.async {
                for (i, neopixelView) in self.neopixelsContainerView.subviews.enumerated() where i < pixelColors.count {
                    neopixelView.backgroundColor = pixelColors[i]
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        lightSequenceAnimation?.stop()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update Neopixels scale to match the aspect fit circuit image
        let originalSize = neopixelsContainerWidthConstraint.constant
        let minDimension = min(self.view.bounds.width, self.view.bounds.height)
        let scale = minDimension / originalSize
        currentScale = scale

        let halfOriginalSize = originalSize/2
        var transform = CGAffineTransform(translationX: -halfOriginalSize, y: -halfOriginalSize)        // Move pivot to top-left
        transform = transform.scaledBy(x: scale, y: scale)      // Scale
        transform = transform.translatedBy(x: halfOriginalSize, y: halfOriginalSize)    // Revert pivot
        transform = transform.translatedBy(x: (self.view.bounds.width - minDimension) / (2 * scale), y: (self.view.bounds.height - minDimension) / (2 * scale))     // Center in circuit image

        neopixelsContainerView.transform = transform
    }

    private func lightSequenceGeneratorForTag(_ tag: Int) -> LightSequenceGenerator? {
        let id = tag - PixelsPreviewViewController.kButtonStartTag
        let lightSequence: LightSequenceGenerator?
               switch id {
               case 0: lightSequence = RotateLightSequence()
               case 1: lightSequence = PulseLightSequence()
               case 2: lightSequence = SizzleLightSequence()
               case 3: lightSequence = SweepLightSequence()
               default: lightSequence = nil
               }

        return lightSequence
    }

    // MARK: - Actions
    @IBAction func setLightSequence(_ sender: UIButton) {
        //DLog("neopixelSetLightSequence: \(tag)")
        if let lightSequenceGenerator = lightSequenceGeneratorForTag(tag) {
            AdafruitBoard.shared.neopixelStartLightSequence(lightSequenceGenerator)
        }
    }

}
