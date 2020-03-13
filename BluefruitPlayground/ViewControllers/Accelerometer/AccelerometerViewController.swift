//
//  AccelerometerViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import SceneKit

class AccelerometerViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "AccelerometerViewController"

    // UI
    @IBOutlet weak var sceneView: SCNView!

    // Data
    private var acceleration = BlePeripheral.AccelerometerValue(x: 0, y: 0, z: 0)
    private var circuitNode: SCNNode?
    private var valuesPanelViewController: AccelerometerPanelViewController!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add panels 
        valuesPanelViewController = (addPanelViewController(storyboardIdentifier: AccelerometerPanelViewController.kIdentifier) as! AccelerometerPanelViewController)

        // Load scene
        if let scene = AdafruitBoardsManager.shared.currentBoard?.assetScene {
           
            circuitNode = scene.rootNode.childNode(withName: "root", recursively: false)!
            
            // Setup scene
            sceneView.scene = scene
            sceneView.autoenablesDefaultLighting = true
            sceneView.isUserInteractionEnabled = true
        }
        
        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("accelerometer_title")
        moduleHelpMessage = localizationManager.localizedString("accelerometer_help")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        let board = AdafruitBoardsManager.shared.currentBoard
        if let acceleration = board?.accelerometerLastValue() {
            self.acceleration = acceleration
        }
        updateValueUI()

        // Set delegate
        board?.accelerometerDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegate
        let board = AdafruitBoardsManager.shared.currentBoard
        board?.accelerometerDelegate = nil
    }

    // MARK: - UI
    private func updateValueUI() {
        // Calculate Euler Angles
        let eulerAngles = AccelerometerUtils.accelerationToEuler(acceleration)
        //DLog("Euler: pitch: \(eulerAngles.x) yaw: \(eulerAngles.y) roll: \(eulerAngles.z)")

        // Update circuit model orientation
        SCNTransaction.animationDuration = BlePeripheral.kAdafruitSensorDefaultPeriod
        circuitNode?.eulerAngles = eulerAngles

        // Update panel
        valuesPanelViewController.accelerationReceived(acceleration: self.acceleration, eulerAngles: eulerAngles)
    }
}

// MARK: - CPBBleAccelerometerDelegate
extension AccelerometerViewController: AdafruitAccelerometerDelegate {
    func adafruitAccelerationReceived(_ acceleration: BlePeripheral.AccelerometerValue) {
        self.acceleration = acceleration
        updateValueUI()
    }
}
