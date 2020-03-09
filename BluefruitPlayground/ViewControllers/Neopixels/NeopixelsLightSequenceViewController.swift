//
//  NeopixelsLightSequenceViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import FlexColorPicker

class NeopixelsLightSequenceViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "NeopixelsLightSequenceViewController"

    // UI
    @IBOutlet weak var sequencesStackView: UIStackView!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var speedSlider: UISlider!

    // Data
    private var previewViewControllers = [PixelsPreviewViewController]()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add previewViewControllers
        addPreviewViewControllers()
        
        // Set previewViewControllers tags
        _ = previewViewControllers.map {$0.tag = $0.view.superview?.tag ?? 0}

        // Set initial speed
        let speed = AdafruitBoard.kLightSequenceDefaultSpeed
        speedSlider.value = Float(speed)
        //speedChanged(speedSlider)
        _ = previewViewControllers.map {$0.speed = speed}

        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("neopixels_sequence_title")
        speedLabel.text = localizationManager.localizedString("neopixels_sequence_speed")
    }

    /*
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? PixelsPreviewViewController {
            previewViewControllers.append(viewController)
        }
    }*/

    // MARK: - UI
    private func addPreviewViewControllers() {
        guard let model = AdafruitBoardsManager.shared.currentBoard?.model else { return }
        
        
        let storyboardIdentifier: String?
        switch model {
        case .circuitPlaygroundBluefruit:
            storyboardIdentifier = "CPBPixelsPreviewViewController"
        case .clue_nRF52840:
            storyboardIdentifier = "CluePixelsPreviewViewController"
        default:
            storyboardIdentifier = nil
        }
        
        guard let identifier = storyboardIdentifier else { return }
        
        // Add previewViewControllers to designated views (views that tags >= 100)
        for i in 100..<104 {
            if let containerView = sequencesStackView.viewWithTag(i), let viewController = storyboard?.instantiateViewController(withIdentifier: identifier) as? PixelsPreviewViewController {
                
                ChildViewControllersManagement.addChildViewController(viewController, contentView: containerView, parentViewController: self)
                
                previewViewControllers.append(viewController)
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func speedChanged(_ sender: UISlider) {
        let speed = Double(sender.value)
        DLog("speed: \(speed)")

        let board = AdafruitBoardsManager.shared.currentBoard
        board?.neopixelCurrentLightSequenceAnimationSpeed = speed
        _ = previewViewControllers.map {$0.speed = speed}
    }
}
