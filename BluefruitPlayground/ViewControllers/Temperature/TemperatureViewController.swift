//
//  TemperatureViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class TemperatureViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "TemperatureViewController"
    private static let kTemperatureUnitSettingsKey = "kTemperatureUnitSettingsKey"

    // UI
    @IBOutlet weak var unitsButton: UIButton!
    @IBOutlet weak var temperatureLabel: UILabel!

    // Data
    private var chartPanelViewController: TemperaturePanelViewController!
    private var isCelsius = false
    private var temperatureCelsius: Float?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add panels
        chartPanelViewController = (addPanelViewController(storyboardIdentifier: TemperaturePanelViewController.kIdentifier) as! TemperaturePanelViewController)

        // Get temperature units
        isCelsius = UserDefaults.standard.bool(forKey: TemperatureViewController.kTemperatureUnitSettingsKey)
        chartPanelViewController.isCelsius = isCelsius

        // UI
        updateUnitsButton()
        updateValueUI()

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("temperature_title")
        moduleHelpMessage = localizationManager.localizedString("temperature_help")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        let board = AdafruitBoardsManager.shared.currentBoard
        temperatureCelsius = board?.temperatureLastValue()
        updateValueUI()

        // Set delegate
        board?.temperatureDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegate
        let board = AdafruitBoardsManager.shared.currentBoard
        board?.temperatureDelegate = nil
    }

    // MARK: - UI
    private func updateUnitsButton() {
        unitsButton.setTitle(LocalizationManager.shared.localizedString(isCelsius ? "temperature_units_celsius":"temperature_units_farenheit"), for: .normal)
    }

    private func updateValueUI() {
        // Units
        let units = LocalizationManager.shared.localizedString(isCelsius ? "temperature_units_celsius":"temperature_units_farenheit")

        // Temperature
        let text: String
        if let temperatureCelsius = temperatureCelsius {
            let temperature = isCelsius ? temperatureCelsius : (temperatureCelsius * 1.8 + 32)
            text = String(format: "%.1f%@", temperature, units)
        } else {  // Undefined
            text = String(format: "--%@", units)
        }

        // Update label
        temperatureLabel.text = text

    }

    // MARK: - Actions
    @IBAction func changeUnits(_ sender: Any) {
        isCelsius = !isCelsius
        UserDefaults.standard.set(isCelsius, forKey: TemperatureViewController.kTemperatureUnitSettingsKey)

        updateUnitsButton()
        updateValueUI()

        chartPanelViewController.isCelsius = isCelsius
    }
}

// MARK: - CPBBleTemperatureDelegate
extension TemperatureViewController: AdafruitTemperatureDelegate {
    func adafruitTemperatureReceived(_ temperature: Float) {
        temperatureCelsius = temperature
        updateValueUI()

        // Update chart
        chartPanelViewController.updateLastEntryAddedToDataSeries()
    }
}
