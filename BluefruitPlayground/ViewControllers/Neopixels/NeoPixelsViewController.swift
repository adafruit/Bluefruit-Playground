//
//  NeoPixelsViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

// Note: canCancelContentTouch set to false on baseScrollView because FlexiColor
class NeoPixelsViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "NeoPixelsViewController"

    // UI
    @IBOutlet weak var selectAllButton: UIButton!
    @IBOutlet weak var unselectAllButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    // Data
    private var circuitViewController: CircuitViewController!
    private var isNeopixelSelected: [Bool] {
        return circuitViewController.isNeopixelSelected
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add panels
        let _ = addPanelViewController(storyboardIdentifier: NeopixelsLightSequenceViewController.kIdentifier)

        let colorPaletteViewController = addPanelViewController(storyboardIdentifier: NeopixelsColorPaletteViewController.kIdentifier) as! NeopixelsColorPaletteViewController
        colorPaletteViewController.delegate = self
        
        let colorWheelViewController = addPanelViewController(storyboardIdentifier: NeopixelsColorWheelViewController.kIdentifier) as! NeopixelsColorWheelViewController
        colorWheelViewController.delegate = self

        // UI Initial state
        showSelectionButtons(false)
        circuitViewController.showSelectionAnimated(false)
        circuitViewController.neopixelSelectAll(animated: false)

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("neopixels_title")

        moduleHelpMessage = localizationManager.localizedString("neopixels_help")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        circuitViewController.neopixelsReset(animated: false)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? CircuitViewController {
            circuitViewController = viewController
        }
    }
    
    // MARK: - Actions
    @IBAction func neopixelsSelectAll(_ sender: Any) {
        circuitViewController.neopixelSelectAll(animated: true)
    }
    
    @IBAction func neopixelsClear(_ sender: Any) {
        circuitViewController.neopixelClear()
    }
    
    @IBAction func neopixelsReset(_ sender: Any) {
        circuitViewController.neopixelsReset(animated: true)
    }
    
    private func selectColor(_ color: UIColor, baseColor: UIColor) {
        // Update circuit
        circuitViewController.setNeopixelsColor(color, onlySelected: true, animated: true, baseColor: baseColor)
    }
    
    // MARK: - Page Management
    override func onPageChanged(_ page: Int) {
        super.onPageChanged(page)
        
        let areNeopixelsVisible = page != 0
        UIView.animate(withDuration: 0.2) {
            self.showSelectionButtons(areNeopixelsVisible)
        }
        self.circuitViewController.showSelectionAnimated(areNeopixelsVisible)
    }
    
    private func showSelectionButtons(_ show: Bool) {
        selectAllButton.alpha = show ? 1:0
        unselectAllButton.alpha = show ? 1:0
    }
}

// MARK: - NeopixelsColorPaletteViewControllerDelegate
extension NeoPixelsViewController: NeopixelsColorPaletteViewControllerDelegate {
    func colorPaletteColorSelected(color: UIColor, baseColor: UIColor) {
        selectColor(color, baseColor: baseColor)
    }

}

// MARK: - NeopixelColorWheelViewControllerDelegate
extension NeoPixelsViewController: NeopixelColorWheelViewControllerDelegate {
    func colorWheelColorSelected(color: UIColor, baseColor: UIColor) {
        selectColor(color, baseColor: baseColor)
    }
}
