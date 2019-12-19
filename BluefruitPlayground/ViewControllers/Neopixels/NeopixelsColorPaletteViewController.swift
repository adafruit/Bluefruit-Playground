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
    private static let kDefaultBrightness: CGFloat = 0.3

    // Params
    weak var delegate: NeopixelsColorPaletteViewControllerDelegate?

    // UI
    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var paletteStackView: UIStackView!

    @IBOutlet open var brightnessSlider: NormalBrightnessSliderControl? {
        get {
            return colorPicker.normalBrightnessSlider
        }
        set {
            // Change brightness on touchUp
            newValue?.addTarget(self, action: #selector(brightnessChanged), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            
            // Set initial value (as color becasue that what the FlexColorPicker api needs)
            newValue?.setSelectedHSBColor(HSBColor(color: UIColor.init(white: NeopixelsColorPaletteViewController.kDefaultBrightness, alpha: 1)), isInteractive: false)
        }
    }
    
    // Data
    private let colorPicker = NormalBrightnessColorPickerController()
    
    private var paletteButtons: [UIButton] = []
    private var initialColors: [UIColor] = []
    
    private var colorButtonSelected: UIButton?
    private var brightness: CGFloat = NeopixelsColorPaletteViewController.kDefaultBrightness
 
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Note: Use the same color and borderWidth that FlexColorPicker uses internally so it looks the same
        let borderColor = #colorLiteral(red: 0.7089999914, green: 0.7089999914, blue: 0.7089999914, alpha: 1)
         
        paletteButtons = paletteStackView.getAllSubviewsWithClass() as [UIButton]
        for button in paletteButtons {
            button.layer.cornerRadius = 8
            button.layer.masksToBounds = true
            //button.layer.borderWidth = borderWidth
            button.layer.borderColor = borderColor.cgColor
            let color = button.backgroundColor ?? .white
            initialColors.append(color)
        }
        
        // Auto-select first button
        selectButton(paletteButtons.first)
        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("neopixels_palette_title")
        brightnessLabel.text = localizationManager.localizedString("neopixels_palette_brightness")
    }
    
    /*
    // MARK: - UI
    private func updatePreviewColors() {
        for (i, button) in paletteButtons.enumerated() {
            let color = initialColors[i]

            // Set color with brightness
            let hsbColor = HSBColor(color: color)
            
            let colorWithBrightness = hsbColor.withBrightness(brightness).toUIColor()
            button.backgroundColor = colorWithBrightness
            
            // Set highlight color
            let highlightColor = colorWithBrightness.darker() //  brightness > 0.5 ? colorWithBrightness.lighter() :  colorWithBrightness.darker()
            button.setBackgroundColor(color: highlightColor, forState: .highlighted)
        }
    }*/

    // MARK: - Actions
    @IBAction func colorSelected(_ sender: UIButton) {
        //guard let selectedColor = sender.backgroundColor else { return }
        //self.color = selectedColor
        selectButton(sender)
        sendSelectColorWithBrightness()
    }
    
    @IBAction func brightnessChanged(_ sender: BrightnessSliderControl) {
        brightness = CGFloat(sender.thumbView.percentage) / 100
        //DLog("brightness: \(brightness)")
        sendSelectColorWithBrightness()
    }
    
    private func selectButton(_ buttonSelected: UIButton?) {
        let kSelectedBorderWidth: CGFloat = 4
        let kUnselectedBorderWidth: CGFloat = 1 / UIScreen.main.scale
        
        self.colorButtonSelected = buttonSelected
        for button in paletteButtons {
            button.layer.borderWidth = button === buttonSelected ? kSelectedBorderWidth : kUnselectedBorderWidth
        }
    }
    
    private func sendSelectColorWithBrightness() {
        guard let color = colorButtonSelected?.backgroundColor else { return }
        guard color != .clear else { return }
        
        let hsbColor = HSBColor(color: color)
        let colorWithBrighness = hsbColor.withBrightness(brightness).toUIColor()
        
        delegate?.colorPaletteColorSelected(color: colorWithBrighness)
    }
}
