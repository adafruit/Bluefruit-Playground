//
//  NeopixelsColorWheelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 17/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import FlexColorPicker

protocol NeopixelColorWheelViewControllerDelegate: class {
    func colorWheelColorSelected(color: UIColor, baseColor: UIColor)
}

class NeopixelsColorWheelViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "NeopixelsColorWheelViewController"

    // Config
    private static let kDefaultBrightness: CGFloat = 0.3

    // Data
    private var color: UIColor = .white
    private var brightness: CGFloat = NeopixelsColorWheelViewController.kDefaultBrightness

    // UI
    @IBOutlet weak var brightnessLabel: UILabel!

    @IBOutlet open var rectangularHsbPalette: RectangularPaletteControl? {
        get {
            return colorPicker.rectangularHsbPalette
        }
        set {
            colorPicker.rectangularHsbPalette = newValue
        }
    }

    @IBOutlet public var colorPreview: ColorPreviewWithHex? {
        get {
            return colorPicker.colorPreview
        }
        set {
            colorPicker.colorPreview = newValue
        }
    }

    @IBOutlet open var brightnessSlider: NormalBrightnessSliderControl? {
        get {
            return colorPicker.normalBrightnessSlider
        }
        set {
            // Change brightness on touchUp
            newValue?.addTarget(self, action: #selector(brightnessChanged), for: [.touchUpInside, .touchUpOutside, .touchCancel])

            // Set initial value (as color becasue that what the FlexColorPicker api needs)
            newValue?.setSelectedHSBColor(HSBColor(color: UIColor.init(white: NeopixelsColorWheelViewController.kDefaultBrightness, alpha: 1)), isInteractive: false)
        }
    }

    // Params
    weak var delegate: NeopixelColorWheelViewControllerDelegate?

    // Data
    public let colorPicker = NormalBrightnessColorPickerController()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup color picker
        colorPicker.delegate = self

        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("neopixels_colorwheel_title")
        brightnessLabel.text = localizationManager.localizedString("neopixels_colorwheel_brightness")
    }

    // MARK: - Actions
    @IBAction func colorRecognizerAction(_ sender: UILongPressGestureRecognizer) {
        // Send the new color only when the user releases the finger
        if sender.state == .ended || sender.state == .cancelled || sender.state == .failed {
            sendSelectColorWithBrightness()
        }
    }

    @IBAction func brightnessChanged(_ sender: BrightnessSliderControl) {
        brightness = CGFloat(sender.thumbView.percentage) / 100
        sendSelectColorWithBrightness()
    }

    private func sendSelectColorWithBrightness() {
        guard color != .clear else { return }

        let hsbColor = HSBColor(color: color)
        let colorWithBrighness = hsbColor.withBrightness(brightness).toUIColor()

        delegate?.colorWheelColorSelected(color: colorWithBrighness, baseColor: color)
    }
}

// MARK: - ColorPickerControllerProtocol
extension NeopixelsColorWheelViewController: ColorPickerDelegate {

    func colorPicker(_ colorPicker: ColorPickerController, confirmedColor: UIColor, usingControl: ColorControl) {
        //DLog("confirmed color: \(confirmedColor)")
        self.color = confirmedColor
        sendSelectColorWithBrightness()
    }

    func colorPicker(_ colorPicker: ColorPickerController, selectedColor: UIColor, usingControl: ColorControl) {
        //DLog("selectedColor color: \(selectedColor)")
        self.color = selectedColor
    }
}
