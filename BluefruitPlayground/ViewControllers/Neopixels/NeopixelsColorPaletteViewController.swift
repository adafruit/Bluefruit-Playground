//
//  NeopixelsColorPaletteViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import FlexColorPicker

protocol NeopixelsColorPaletteViewControllerDelegate: class {
    func colorPaletteColorSelected(color: UIColor)
}

class NeopixelsColorPaletteViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "NeopixelsColorPaletteViewController"
    
    // Config
    private static let kIsBrightnessPreviewEnabled = false
    private static let kDefaultBrightness: CGFloat = 0.3
    
    // UI
    @IBOutlet weak var brightnessLabel: UILabel!
    
    // Params
    weak var delegate: NeopixelsColorPaletteViewControllerDelegate?
    
    // UI
    @IBOutlet weak var paletteStackView: UIStackView!
    
    @IBOutlet open var brightnessSlider: NormalBrightnessSliderControl? {
        get {
            return colorPicker.normalBrightnessSlider
        }
        set {
            // Set initial value (as color becasue that what the FlexColorPicker api needs)
            newValue?.setSelectedHSBColor(HSBColor(color: UIColor.init(white: NeopixelsColorPaletteViewController.kDefaultBrightness, alpha: 1)), isInteractive: false)
            
            if NeopixelsColorPaletteViewController.kIsBrightnessPreviewEnabled {
                colorPicker.normalBrightnessSlider = newValue
            }
        }
    }
    
    // Data
    private let colorPicker = NormalBrightnessColorPickerController()
    
    private var paletteButtons: [UIButton] = []
    private var initialColors: [UIColor] = []
    private var brightness: CGFloat = NeopixelsColorPaletteViewController.kDefaultBrightness

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Note: Use the same color and borderWidth that FlexColorPicker uses internally so it looks the same
        let borderColor = #colorLiteral(red: 0.7089999914, green: 0.7089999914, blue: 0.7089999914, alpha: 1)
        let borderWidth: CGFloat = 1 / UIScreen.main.scale
        
        paletteButtons = paletteStackView.getAllSubviewsWithClass() as [UIButton]
        for button in paletteButtons {
            button.layer.cornerRadius = 8
            button.layer.masksToBounds = true
            button.layer.borderWidth = borderWidth
            button.layer.borderColor = borderColor.cgColor
            let color = button.backgroundColor ?? .white
            initialColors.append(color)
        }
        
        if NeopixelsColorPaletteViewController.kIsBrightnessPreviewEnabled {
            updatePreviewColors()
        }
        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("neopixels_palette_title")
        brightnessLabel.text = localizationManager.localizedString("neopixels_palette_brightness")
    }
    
    // MARK: - UI
    private func updatePreviewColors() {
        for (i, button) in paletteButtons.enumerated() {
            let color = initialColors[i]

            // Set color with brightness
            let hsbColor = HSBColor(color: color)
            
            //let visualBrightness = NeopixelsUIUtils.visualBrightnessFromBrightness(brightness)
            //DLog("visualBrightness: \(visualBrightness)")
            let colorWithBrightness = hsbColor.withBrightness(brightness).toUIColor()
            button.backgroundColor = colorWithBrightness
            
            // Set highlight color
            let highlightColor = colorWithBrightness.darker() //  brightness > 0.5 ? colorWithBrightness.lighter() :  colorWithBrightness.darker()
            button.setBackgroundColor(color: highlightColor, forState: .highlighted)
        }
    }

    // MARK: - Actions
    @IBAction func colorSelected(_ sender: UIButton) {
        guard let color = sender.backgroundColor else { return }
        let selectedColor: UIColor
        if NeopixelsColorPaletteViewController.kIsBrightnessPreviewEnabled {
            selectedColor = color
        }
        else {
            let hsbColor = HSBColor(color: color)
            selectedColor = hsbColor.withBrightness(brightness).toUIColor()
        }
        delegate?.colorPaletteColorSelected(color: selectedColor)
    }
    
    @IBAction func brightnessChanged(_ sender: BrightnessSliderControl) {
        brightness = CGFloat(sender.thumbView.percentage) / 100
        //DLog("brightness: \(brightness)")
        if NeopixelsColorPaletteViewController.kIsBrightnessPreviewEnabled {
            updatePreviewColors()
        }
    }
}

