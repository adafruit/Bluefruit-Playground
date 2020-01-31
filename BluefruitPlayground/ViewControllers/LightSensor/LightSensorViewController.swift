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

    // Data
    private var circuitViewController: CircuitViewController!
    private var lightmeterPanelViewController: LightSensorPanelViewController!
    private var light: Float?
    private var chartPanelViewController: LightChartPanelViewController!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add panels
        lightmeterPanelViewController = (addPanelViewController(storyboardIdentifier: LightSensorPanelViewController.kIdentifier) as! LightSensorPanelViewController)

        chartPanelViewController = (addPanelViewController(storyboardIdentifier: LightChartPanelViewController.kIdentifier) as! LightChartPanelViewController)

        
        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("lightsensor_title")
        moduleHelpMessage = localizationManager.localizedString("lightsensor_help")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        self.light = CPBBle.shared.lightLastValue()
        updateValueUI()
        
        // Set delegate
        CPBBle.shared.lightDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove delegate
        CPBBle.shared.lightDelegate = nil
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? CircuitViewController {
            circuitViewController = viewController
        }
    }
    
    // MARK: - UI
    private func updateValueUI() {
        if let light = self.light {
            lightmeterPanelViewController.lightValueReceived(light)
            
            // Update chart
            chartPanelViewController.lightValueReceived()
        }
    }
}

// MARK: - CPBBleLightDelegate
extension LightSensorViewController: CPBBleLightDelegate {
    func cpbleLightReceived(_ light: Float) {
        self.light = light
        updateValueUI()
    }
}

