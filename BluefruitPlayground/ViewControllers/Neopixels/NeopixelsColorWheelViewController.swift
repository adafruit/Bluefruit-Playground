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
    func colorWheelColorSelected(color: UIColor)
}

class NeopixelsColorWheelViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "NeopixelsColorWheelViewController"
    
    // Config
    private static let kIsBrightnessPreviewEnabled = false
    private static let kDefaultBrightness: CGFloat = 0.3
    
    // Data
    private var selectedColorWithBrightness: UIColor?
    private var brightness: CGFloat = NeopixelsColorWheelViewController.kDefaultBrightness  // Only used when kIsBrightnessPreviewEnabled == false
    
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
            // Set initial value (as color becasue that what the FlexColorPicker api needs)
            newValue?.setSelectedHSBColor(HSBColor(color: UIColor.init(white: NeopixelsColorWheelViewController.kDefaultBrightness, alpha: 1)), isInteractive: false)
            
            if NeopixelsColorWheelViewController.kIsBrightnessPreviewEnabled {
                colorPicker.normalBrightnessSlider = newValue
            }
           
        }
    }
    
    // Params
    weak var delegate: NeopixelColorWheelViewControllerDelegate?
    
    // Data
    public let colorPicker = NormalBrightnessColorPickerController()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            if let selectedColorWithBrightness = selectedColorWithBrightness {
                delegate?.colorWheelColorSelected(color: selectedColorWithBrightness)
            }
        }
    }
    
    @IBAction func brightnessChanged(_ sender: BrightnessSliderControl) {
        if !NeopixelsColorWheelViewController.kIsBrightnessPreviewEnabled {
            brightness = CGFloat(sender.thumbView.percentage) / 100
        }
    }
}

// MARK: - ColorPickerControllerProtocol
extension NeopixelsColorWheelViewController: ColorPickerDelegate {
    
    func colorPicker(_ colorPicker: ColorPickerController, confirmedColor: UIColor, usingControl: ColorControl) {
        //DLog("confirmed color: \(confirmedColor)")
        updateSelectedColorWithBrightnessWithColor(confirmedColor)
        if let selectedColorWithBrightness = self.selectedColorWithBrightness {
            delegate?.colorWheelColorSelected(color: selectedColorWithBrightness)
        }
    }
    
    func colorPicker(_ colorPicker: ColorPickerController, selectedColor: UIColor, usingControl: ColorControl) {
        //DLog("selectedColor color: \(selectedColor)")
        updateSelectedColorWithBrightnessWithColor(selectedColor)
        //delegate?.colorWheelColorSelected(color: selectedColor)
    }
    
    private func updateSelectedColorWithBrightnessWithColor(_ selectedColor: UIColor) {
        if NeopixelsColorWheelViewController.kIsBrightnessPreviewEnabled {
            self.selectedColorWithBrightness = selectedColor
        }
        else {
            let hsbColor = HSBColor(color: selectedColor)
            let colorWithBrightness = hsbColor.withBrightness(self.brightness).toUIColor()
            self.selectedColorWithBrightness = colorWithBrightness
        }
    }
}

