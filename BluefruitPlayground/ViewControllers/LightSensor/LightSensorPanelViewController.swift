//
//  LightSensorPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 18/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class LightSensorPanelViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "LightSensorPanelViewController"

    // Config
    private static let kScaleMinLux: Float = 0
    private static let kScaleMaxLux: Float = 800        // Note: What is a sensible value here??

    // UI
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var scaleImageView: UIImageView!
    @IBOutlet weak var maskView: UIView!
    @IBOutlet weak var maskViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var unitsLabel: UILabel!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // UI
        scaleImageView.mask = maskView
        setScaleProgress(0)     // Initial value

        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("lightsensor_panel_title")
        unitsLabel.text = localizationManager.localizedString("lightsensor_panel_unit")
    }

    private func setScaleProgress(_ value: Float) {
        let minValue: Float = 0.001       // 0 breaks the setMultiplier function
        let maxValue: Float = 1
        let adjustedValue = max(minValue, min(maxValue, value))

        //DLog("progress: \(adjustedValue)")
        NSLayoutConstraint.setMultiplier(multiplier: CGFloat(adjustedValue), constraint: &self.maskViewWidthConstraint)
        UIView.animate(withDuration: BlePeripheral.kAdafruitLightDefaultPeriod, delay: 0, options: .curveLinear, animations: {
            self.scaleImageView.layoutIfNeeded()
        })
    }

    // MARK: - Data
    func lightValueReceived(_ light: Float) {

        valueLabel.text = String(format: "%.0f", light)

        let adjustedValue = min(max(light, LightSensorPanelViewController.kScaleMinLux), LightSensorPanelViewController.kScaleMaxLux)
        let progress = (adjustedValue - LightSensorPanelViewController.kScaleMinLux) / (LightSensorPanelViewController.kScaleMaxLux-LightSensorPanelViewController.kScaleMinLux)
        
        setScaleProgress(progress)
    }
}
