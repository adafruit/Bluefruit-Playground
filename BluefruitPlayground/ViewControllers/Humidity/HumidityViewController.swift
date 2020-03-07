//
//  HumidityViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class HumidityViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "HumidityViewController"
    private static let kHumidityUnitSettingsKey = "kHumidityUnitSettingsKey"

    // UI
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var humidityFillImageView: UIImageView!
    
    // Data
    private var fillMaskView = UIView()
    private var chartPanelViewController: HumidityPanelViewController!
    private var humidity: Float?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add panels
        chartPanelViewController = (addPanelViewController(storyboardIdentifier: HumidityPanelViewController.kIdentifier) as! HumidityPanelViewController)

        // UI
        fillMaskView.backgroundColor = .white
        humidityFillImageView.mask = fillMaskView

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("humidity_title")
        moduleHelpMessage = localizationManager.localizedString("humidity_help")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        let board = AdafruitBoardsManager.shared.currentBoard
        humidity = board?.humidityLastValue()
        updateValueUI()

        // Set delegate
        board?.humidityDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegate
        let board = AdafruitBoardsManager.shared.currentBoard
        board?.humidityDelegate = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    // MARK: - UI
    private func updateValueUI() {
        // Humidity
        let text: String
        if let humidity = humidity {
            text = String(format: "%.1f%%", humidity)
            
            // Update chart
            chartPanelViewController.humidityValueReceived()
            
        } else {  // Undefined
            text = String(format: "--%%")
        }
        
        // Update label
        humidityLabel.text = text
        
        // Water drop mask
        setWaterDropProgress((humidity ?? 0) / 100)
    }
    
    private func setWaterDropProgress(_ value: Float) {
        let minValue: Float = 0
        let maxValue: Float = 1
        let adjustedValue = max(minValue, min(maxValue, value))

        //DLog("progress: \(adjustedValue)")
        let height = humidityFillImageView.bounds.height * CGFloat(adjustedValue)
        fillMaskView.frame = CGRect(x: 0, y: humidityFillImageView.bounds.height - height, width: humidityFillImageView.bounds.width, height: height)
    }
}

// MARK: - CPBBleHumidityDelegate
extension HumidityViewController: AdafruitHumidityDelegate {
    func adafruitHumidityReceived(_ humidity: Float) {
        self.humidity = humidity
        updateValueUI()
    }
}
