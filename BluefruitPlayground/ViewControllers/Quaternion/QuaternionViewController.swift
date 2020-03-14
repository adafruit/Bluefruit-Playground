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
    
    // Config
    private static let kDisableZComponent = true        // Z component is disabled until gyro calibration is implemented

    // UI
    @IBOutlet weak var sceneView: SCNView!

    // Data
    private var quaternion: BlePeripheral.QuaternionValue?
    private var boardNode: SCNNode?
    private var valuesPanelViewController: QuaternionPanelViewController!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add panels 
        valuesPanelViewController = (addPanelViewController(storyboardIdentifier: QuaternionPanelViewController.kIdentifier) as! QuaternionPanelViewController)

        // Load scene
        if let scene = AdafruitBoardsManager.shared.currentBoard?.assetScene {
            boardNode = scene.rootNode.childNode(withName: "root", recursively: false)!
            
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
        guard let quaternion = quaternion else { return }
        
        let scnQuaternion = simd_quatf(ix: quaternion.x, iy: quaternion.y, iz: QuaternionViewController.kDisableZComponent ? 0 : quaternion.z, r: quaternion.w)

        // Update circuit model orientation
        SCNTransaction.animationDuration = BlePeripheral.kAdafruitSensorDefaultPeriod
        boardNode?.simdOrientation = scnQuaternion
        
        // Update panel
        let (x, y, z) = QuaternionUtils.quaternionToEuler(quaternion: quaternion)
        let eulerAngles = simd_float3(x, y, z)
        //DLog("Euler: pitch: \(eulerAngles.xquaternionToEuler) yaw: \(eulerAngles.y) roll: \(eulerAngles.z)")
        valuesPanelViewController.accelerationReceived(quaternion: scnQuaternion, eulerAngles: eulerAngles)
    }
}

// MARK: - CPBBleQuaternionDelegate
extension QuaternionViewController: AdafruitQuaternionDelegate {
    func adafruitQuaternionReceived(_ quaternion: BlePeripheral.QuaternionValue) {
        self.quaternion = quaternion
        updateValueUI()
    }
}
