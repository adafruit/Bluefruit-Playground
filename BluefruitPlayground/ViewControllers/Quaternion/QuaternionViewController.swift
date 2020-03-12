//
//  QuaternionViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import SceneKit

class QuaternionViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "QuaternionViewController"

    // UI
    @IBOutlet weak var sceneView: SCNView!

    // Data
    private var quaternion = BlePeripheral.QuaternionValue(qx: 0, qy: 0, qz: 0, qw: 1)
    private var circuitNode: SCNNode?
    private var valuesPanelViewController: QuaternionPanelViewController!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add panels 
        valuesPanelViewController = (addPanelViewController(storyboardIdentifier: QuaternionPanelViewController.kIdentifier) as! QuaternionPanelViewController)

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
        self.title = localizationManager.localizedString("quaternion_title")
        moduleHelpMessage = localizationManager.localizedString("quaternion_help")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        let board = AdafruitBoardsManager.shared.currentBoard
        if let value = board?.quaternionLastValue() {
            self.quaternion = value
        }
        updateValueUI()

        // Set delegate
        board?.quaternionDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegate
        let board = AdafruitBoardsManager.shared.currentBoard
        board?.quaternionDelegate = nil
    }

    // MARK: - UI
    private func updateValueUI() {
        // Calculate Euler Angles
        let eulerAngles = QuaternionUtils.quaternionToEuler(quaternion: quaternion)
        //DLog("Euler: pitch: \(eulerAngles.x) yaw: \(eulerAngles.y) roll: \(eulerAngles.z)")

        // Update circuit model orientation
        SCNTransaction.animationDuration = BlePeripheral.kAdafruitQuaternionDefaultPeriod
        circuitNode?.eulerAngles = eulerAngles

        // Update panel
        valuesPanelViewController.accelerationReceived(quaternion: self.quaternion, eulerAngles: eulerAngles)
    }
}

// MARK: - CPBBleQuaternionDelegate
extension QuaternionViewController: AdafruitQuaternionDelegate {
    func adafruitQuaternionReceived(_ quaternion: BlePeripheral.QuaternionValue) {
        self.quaternion = quaternion
        updateValueUI()
    }
}
