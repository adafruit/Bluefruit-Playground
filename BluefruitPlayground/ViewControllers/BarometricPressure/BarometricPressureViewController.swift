//
//  BarometricPressureViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class BarometricPressureViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "BarometricPressureViewController"

    // Config
    private static let kScaleMinHPa: Float = 960
    private static let kScaleMaxHPa: Float = 1060
    
    // UI
    @IBOutlet weak var handImageView: UIImageView!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var minScaleLabel: UILabel!
    @IBOutlet weak var maxScaleLabel: UILabel!
    
    // Data
    private var chartPanelViewController: BarometricPressurePanelViewController!
    private var pressure: Float?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add panels
        chartPanelViewController = (addPanelViewController(storyboardIdentifier: BarometricPressurePanelViewController.kIdentifier) as! BarometricPressurePanelViewController)

        // UI
        minScaleLabel.text = "\(BarometricPressureViewController.kScaleMinHPa)"
        maxScaleLabel.text = "\(BarometricPressureViewController.kScaleMaxHPa)"

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("pressure_title")
        moduleHelpMessage = localizationManager.localizedString("pressure_help")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        let board = AdafruitBoardsManager.shared.currentBoard
        pressure = board?.barometricPressureLastValue()
        updateValueUI()

        // Set delegate
        board?.barometricPressureDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegate
        let board = AdafruitBoardsManager.shared.currentBoard
        board?.barometricPressureDelegate = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    // MARK: - UI
    private func updateValueUI() {
        // BarometricPressure
        let text: String
        if let pressure = pressure {
            text = String(format: "%.0f", pressure)
        } else {  // Undefined
            text = String(format: "--")
        }
        
        // Update label
        pressureLabel.text = text
        
        // Update hand
        updateBarometerUI()
    }
    
    //var testAngle: Float = 0
    private func updateBarometerUI() {
        let adjustedValue = min(max(pressure ?? 0, BarometricPressureViewController.kScaleMinHPa), BarometricPressureViewController.kScaleMaxHPa)
        let progress = (adjustedValue - BarometricPressureViewController.kScaleMinHPa) / (BarometricPressureViewController.kScaleMaxHPa-BarometricPressureViewController.kScaleMinHPa)
        
        let kMinDegress: Float = -136       // min rotation in degress
        let kMaxDegress: Float = 136        // max rotation in degress
        
        let degress = (progress - kMinDegress) / (kMaxDegress-kMinDegress)
        let angle = degress * .pi / 180     // to radians
               
        
        //testAngle = testAngle + 2
        UIView.animate(withDuration: BlePeripheral.kAdafruitSensorDefaultPeriod, delay: 0, options: .curveLinear, animations: {
            self.handImageView.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
            //self.handImageView.transform = CGAffineTransform(rotationAngle: CGFloat(self.testAngle * .pi / 180))
        }, completion: nil)
    }
}

// MARK: - CPBBleBarometricPressureDelegate
extension BarometricPressureViewController: AdafruitBarometricPressureDelegate {
    func adafruitBarometricPressureReceived(_ pressure: Float) {
        self.pressure = pressure
        updateValueUI()

        // Update chart
        chartPanelViewController.updateLastEntryAddedToDataSeries()
    }
}
