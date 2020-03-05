//
//  CircuitViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

protocol CircuitViewControllerDelegate: class {
    func circuitViewNeopixelSelectionChanged()
}

class CircuitViewController: UIViewController {
    // Constant
    private static let kNumNeopixels = 10
    private static let kSelectedBorderWidth: CGFloat = 3
    private static let kUnselectedButtonAlpha: CGFloat = 0.02       // Not 0 because it is automatically hidden by the OS and breaks interaction

    // UI
    @IBOutlet weak var neopixelsContainerView: UIView!
    @IBOutlet weak var neopixelsContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsContainerView: UIView!
    @IBOutlet weak var neopixelViewWidthConstraint: NSLayoutConstraint!

    // Params
    weak var delegate: CircuitViewControllerDelegate?
    var isNeopixelSelected = [Bool](repeating: false, count: CircuitViewController.kNumNeopixels)

    // Data
    private var currentScale: CGFloat = 0
    private var isFirstTime = true

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
        for (i, neopixelView) in self.neopixelsContainerView.subviews.enumerated() where i < self.isNeopixelSelected.count {
            neopixelView.backgroundColor = .clear
        }
        //neopixelsReset(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Create a button for each neopixel
        if isFirstTime {
            createButtons()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()

            isFirstTime = false
        }

        // Notifications
        registerNotifications(enabled: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Notifications
        registerNotifications(enabled: false)
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

        // Update buttons position. Buttons should be position over the neopixel but they should have at least 44points size to be touchable
        buttonsContainerView.transform = transform
        let selectedWidth = CircuitViewController.kSelectedBorderWidth / scale
        for (i, button) in buttonsContainerView.subviews.enumerated() where neopixelsContainerView.subviews.count > i {
            button.center = neopixelsContainerView.subviews[i].center
            button.layer.borderWidth = selectedWidth
        }
    }

    // MARK: - Notifications
    private var didUpdateNeopixelLightSequenceObserver: NSObjectProtocol?

    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            didUpdateNeopixelLightSequenceObserver = notificationCenter.addObserver(forName: .didUpdateNeopixelLightSequence, object: nil, queue: nil) { [weak self] notification in
                guard let self = self else { return }

                // Get current colors
                guard let pixelsBytes = notification.userInfo?[AdafruitBoard.NotificationUserInfoKey.value.rawValue] as? [[UInt8]] else { return }

                    // Pixel Bytes are GRB
                let pixelColors = pixelsBytes.map { UIColor(red: CGFloat($0[1])/255.0, green: CGFloat($0[0])/255.0, blue: CGFloat($0[2])/255.0, alpha: 1.0) }

                // Update UI colors (on main thread)
                DispatchQueue.main.async {
                    for (i, neopixelView) in self.neopixelsContainerView.subviews.enumerated() where i < pixelColors.count {
                        neopixelView.backgroundColor = pixelColors[i]
                    }
                }
            }
        } else {
            if let didUpdateNeopixelLightSequenceObserver = didUpdateNeopixelLightSequenceObserver {notificationCenter.removeObserver(didUpdateNeopixelLightSequenceObserver)}
        }
    }

    // MARK: - UI
    private func createButtons() {
        let numNeopixels = neopixelsContainerView.subviews.count
        for i in 0..<numNeopixels {
            let button = UIButton(type: .custom)
            button.tag = i
            button.setTitle(nil, for: .normal)

            let size = 37 / currentScale
            button.frame = CGRect(x: 0, y: 0, width: size, height: size)
            button.addTarget(self, action: #selector(neopixelTapped(_:)), for: .touchUpInside)
            //button.addTarget(self, action: #selector(neopixelDoubleTapped(_:event:)), for: .touchDownRepeat)

            button.layer.borderColor = UIColor.yellow.cgColor
            //button.backgroundColor = UIColor.green
            button.alpha = CircuitViewController.kUnselectedButtonAlpha     // Start unselected

            buttonsContainerView.addSubview(button)
        }
    }

    private func animateCurrentNeopixelSelection() {
        for i in 0..<CircuitViewController.kNumNeopixels {
            updateNeopixelSelection(neopixelId: i, isSelected: isNeopixelSelected[i], animated: true)
        }
    }

    public func updateNeopixelSelection(neopixelId: Int, isSelected: Bool, animated: Bool) {
        guard neopixelId < self.buttonsContainerView.subviews.count else { return }

        let selectedView = buttonsContainerView.subviews[neopixelId]

        if animated {
            // Pre-animation state
            selectedView.transform = isSelected ? CGAffineTransform(scaleX: 1.2, y: 1.2):.identity

            // Animate
            UIView.animate(withDuration: 0.2, animations: {
                selectedView.transform = isSelected ? .identity:CGAffineTransform(scaleX: 1.2, y: 1.2)
                selectedView.alpha = isSelected ? 1:CircuitViewController.kUnselectedButtonAlpha
            }) { (_) in
                selectedView.transform = .identity
            }
        } else {
            selectedView.alpha = isSelected ? 1:CircuitViewController.kUnselectedButtonAlpha
        }

    }

    // MARK: - Actions
    func setNeopixelsColor(_ color: UIColor, onlySelected: Bool, animated: Bool, baseColor: UIColor? = nil) {

        if onlySelected {
            AdafruitBoard.shared.neopixelSetPixelColor(color, pixelMask: isNeopixelSelected)
        } else {
            AdafruitBoard.shared.neopixelSetAllPixelsColor(color)
        }

        // UI Animation
        UIView.animate(withDuration: animated ? 0.1: 0) {
            // Base color is the color withouth the brightness. Used in the circuit representation to show the colors more vividly
            for (i, neopixelView) in self.neopixelsContainerView.subviews.enumerated() {
                if i < self.isNeopixelSelected.count && (!onlySelected || self.isNeopixelSelected[i]) {
                    neopixelView.backgroundColor = baseColor ?? color
                }
            }
        }
    }

    func neopixelSelectAll(animated: Bool) {
        for i in 0..<CircuitViewController.kNumNeopixels {
            isNeopixelSelected[i] = true
            updateNeopixelSelection(neopixelId: i, isSelected: true, animated: animated)
        }
    }

    func neopixelClear() {
       for i in 0..<CircuitViewController.kNumNeopixels {
            isNeopixelSelected[i] = false
            updateNeopixelSelection(neopixelId: i, isSelected: false, animated: true)
        }
    }

    func neopixelsReset(animated: Bool) {
        setNeopixelsColor(.clear, onlySelected: false, animated: animated)
    }

    func showSelectionAnimated(_ show: Bool) {
        if buttonsContainerView.alpha != 1 && show {
            animateCurrentNeopixelSelection()
        }
        //neopixelsContainerView.alpha = show ? 1:0
        buttonsContainerView.alpha = show ? 1:0
    }

    @objc private func neopixelTapped(_ sender: UIButton) {
        guard sender.tag < isNeopixelSelected.count else { return }
        DLog("neopixel \(sender.tag) tapped")

        isNeopixelSelected[sender.tag] = !isNeopixelSelected[sender.tag]
        updateNeopixelSelection(neopixelId: sender.tag, isSelected: isNeopixelSelected[sender.tag], animated: true)
        delegate?.circuitViewNeopixelSelectionChanged()
    }

    /*
    @objc private func neopixelDoubleTapped(_ sender: UIButton, event: UIEvent) {
        guard sender.tag < isNeopixelSelected.count else { return }
        DLog("taps: \(event.allTouches?.first?.tapCount ?? -1)")
        guard let touch = event.allTouches?.first, touch.tapCount == 2 else { return }
        DLog("neopixel \(sender.tag) double tapped")

        for i in 0..<isNeopixelSelected.count {
            isNeopixelSelected[i] = i == sender.tag
        }
        animateCurrentNeopixelSelection()
        delegate?.circuitViewNeopixelSelectionChanged()
    }*/

}
