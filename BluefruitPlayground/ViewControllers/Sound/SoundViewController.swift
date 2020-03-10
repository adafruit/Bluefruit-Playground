//
//  SoundViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class SoundViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "SoundViewController"

    // Config
    private static let kScaleMinHPa: Float = 0
    private static let kScaleMaxHPa: Float = 120
    
    // UI
    @IBOutlet weak var soundLabel: UILabel!
    @IBOutlet weak var soundLevelImageView: UIImageView!
    
    // Data
    private var fillMaskView = UIView()
    private var chartPanelViewController: SoundPanelViewController!
    private var channelSamples: [[Int16]]?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add panels
        chartPanelViewController = (addPanelViewController(storyboardIdentifier: SoundPanelViewController.kIdentifier) as! SoundPanelViewController)

        // UI
        soundLevelImageView.mask = fillMaskView

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("sound_title")
        moduleHelpMessage = localizationManager.localizedString("sound_help")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        let board = AdafruitBoardsManager.shared.currentBoard
        channelSamples = board?.soundLastValue()
        updateValueUI()

        // Set delegate
        board?.soundDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegate
        let board = AdafruitBoardsManager.shared.currentBoard
        board?.soundDelegate = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    // MARK: - UI
    private func updateValueUI() {
        // Sound
        /*
        let text: String
        if let channelSamples = channelSamples {
            text = String(format: "%.0f", pressure)
        } else {  // Undefined
            text = String(format: "--")
        }
        
        // Update label
        pressureLabel.text = text
        */
    }
    
    private func setVolumeProgress(_ value: Float) {
           let minValue: Float = 0
           let maxValue: Float = 1000
           let adjustedValue = max(minValue, min(maxValue, value))

           //DLog("progress: \(adjustedValue)")
           let height = soundLevelImageView.bounds.height * CGFloat(adjustedValue)
           UIView.animate(withDuration: BlePeripheral.kAdafruitSoundSensorDefaultPeriod, delay: 0, options: .curveLinear, animations: {
               self.fillMaskView.frame = CGRect(x: 0, y: self.soundLevelImageView.bounds.height - height, width: self.soundLevelImageView.bounds.width, height: height)
           })
       }

}

// MARK: - CPBBleSoundDelegate
extension SoundViewController: AdafruitSoundDelegate {
    func adafruitSoundReceived(_ channelSamples: [[Int16]]) {
        self.channelSamples = channelSamples
        updateValueUI()

        // Update chart
        chartPanelViewController.updateLastEntryAddedToDataSeries()
    }
}
