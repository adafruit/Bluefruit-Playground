//
//  LightSensorViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 18/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class LightSensorViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "LightSensorViewController"

    // UI
    @IBOutlet weak var boardContainerView: UIView!

    // Data
    private var circuitViewController: CPBBoardViewController!
    private var lightmeterPanelViewController: LightSensorPanelViewController!
    private var light: Float?
    private var chartPanelViewController: LightChartPanelViewController!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add main view
        addBoardViewController()
        
        // Add panels
        lightmeterPanelViewController = (addPanelViewController(storyboardIdentifier: LightSensorPanelViewController.kIdentifier) as! LightSensorPanelViewController)
        
        chartPanelViewController = (addPanelViewController(storyboardIdentifier: LightChartPanelViewController.kIdentifier) as! LightChartPanelViewController)
        
        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("lightsensor_title")
        
        var textStringId: String?
        if let model = AdafruitBoardsManager.shared.currentBoard?.model {
            switch model {
            case .circuitPlaygroundBluefruit:
                textStringId = "lightsensor_help_cpb"
            case .clue_nRF52840:
                textStringId = "lightsensor_help_clue"
            default:
                textStringId = nil
            }
        }
        
        moduleHelpMessage = textStringId == nil ? nil : localizationManager.localizedString(textStringId!)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        let board = AdafruitBoardsManager.shared.currentBoard
        self.light = board?.lightLastValue()
        updateValueUI()

        // Set delegate
        board?.lightDelegate = self
        
        // Force layout to adjust panel widths
        self.view.layoutIfNeeded()

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegate
        let board = AdafruitBoardsManager.shared.currentBoard
        board?.lightDelegate = nil
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? CPBBoardViewController {
            circuitViewController = viewController
        }
    }

    // MARK: - UI
    private func addBoardViewController() {
        guard let model = AdafruitBoardsManager.shared.currentBoard?.model else { return }
        
        let storyboardIdentifier: String?
        switch model {
        case .circuitPlaygroundBluefruit:
            storyboardIdentifier = CPBBoardViewController.kIdentifier
        case .clue_nRF52840:
            storyboardIdentifier = ClueFrontBoardViewController.kIdentifier
        default:
            storyboardIdentifier = nil
        }
        
        guard let identifier = storyboardIdentifier, let viewController = storyboard?.instantiateViewController(withIdentifier: identifier) else { return }

        ChildViewControllersManagement.addChildViewController(viewController, contentView: boardContainerView, parentViewController: self)
    }
    
    private func updateValueUI() {
        if let light = self.light {
            lightmeterPanelViewController.lightValueReceived(light)
        }
    }
}

// MARK: - CPBBleLightDelegate
extension LightSensorViewController: AdafruitLightDelegate {
    func adafruitLightReceived(_ light: Float) {
        self.light = light
        updateValueUI()

        // Update chart
        chartPanelViewController.updateLastEntryAddedToDataSeries()
    }
}
