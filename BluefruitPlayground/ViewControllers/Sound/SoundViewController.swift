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
    private static let kScaleMinDBFS: Double = -120     // What is a sensible value here?
    private static let kScaleMaxDBFS: Double = 0
    
    // UI
    @IBOutlet weak var soundLabel: UILabel!
    @IBOutlet weak var soundUnitsLabel: UILabel!
    @IBOutlet weak var soundLevelImageView: UIImageView!
    
    // Data
    private var fillMaskView = UIView()
    private var chartPanelViewController: SoundPanelViewController!
    private var amplitude: Double = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add panels
        chartPanelViewController = (addPanelViewController(storyboardIdentifier: SoundPanelViewController.kIdentifier) as! SoundPanelViewController)

        // UI
        fillMaskView.backgroundColor = .white
        soundLevelImageView.mask = fillMaskView

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("sound_title")
        soundUnitsLabel.text = localizationManager.localizedString("sound_units")
        moduleHelpMessage = localizationManager.localizedString("sound_help")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        let board = AdafruitBoardsManager.shared.currentBoard
        amplitude = board?.soundLastAmplitude() ?? 0
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
        let text = String(format: "%.0f", amplitude)
        soundLabel.text = text
        
        let adjustedValue = min(max(amplitude, SoundViewController.kScaleMinDBFS), SoundViewController.kScaleMaxDBFS)
        let progress = (adjustedValue - SoundViewController.kScaleMinDBFS) / (SoundViewController.kScaleMaxDBFS-SoundViewController.kScaleMinDBFS)
        
       // DLog("amplitude: \(amplitude)  progress: \(String(format: "%.1f", progress))")
        setVolumeProgress(Float(progress))
    }
    
    private func setVolumeProgress(_ value: Float) {
        let minValue: Float = 0
        let maxValue: Float = 1
        let adjustedValue = max(minValue, min(maxValue, value))
        
        let numVolumeLevels = 12            // number of visual levels in soundLevelImageView
        let imageHeight = soundLevelImageView.bounds.height
        let levelHeight = imageHeight / CGFloat(numVolumeLevels)
        
        let height = imageHeight * CGFloat(adjustedValue)
        let adjustedHeight = round(height / levelHeight) * levelHeight      // discrete steps matching the graphic levels
        //DLog("progress: \(adjustedValue) height: \(height)")

       // UIView.animate(withDuration: BlePeripheral.kAdafruitSoundSensorDefaultPeriod, delay: 0, options: .curveLinear, animations: {
            self.fillMaskView.frame = CGRect(x: 0, y: imageHeight - adjustedHeight, width: self.soundLevelImageView.bounds.width, height: adjustedHeight)
        //})
    }
}

// MARK: - CPBBleSoundDelegate
extension SoundViewController: AdafruitSoundDelegate {
    func adafruitSoundReceived(_ amplitudesPerChannel: [Double]) {
        self.amplitude = amplitudesPerChannel.first ?? 0     // Only take into account the first channel
        updateValueUI()

        // Update chart
        chartPanelViewController.updateLastEntryAddedToDataSeries()
    }
}
