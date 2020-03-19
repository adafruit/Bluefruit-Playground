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
    private static let kIsZAxisDisabled = true        // Z axis is disabled until gyro calibration is implemented

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
            boardNode = scene.rootNode.childNode(withName: "root", recursively: false)
            
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

    
    
    var angle: Float = 0
    var quat = simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))

    // MARK: - UI
    private func updateValueUI() {
        guard let quaternion = quaternion else { return }
        guard let boardNode = boardNode else { return }
                
        let scnQuaternion = simd_quatf(vector: simd_float4(quaternion.x, quaternion.y, quaternion.z, quaternion.w))
        //DLog("quat: \(scnQuaternion.vector.x), \(scnQuaternion.vector.y), \(scnQuaternion.vector.z), \(scnQuaternion.vector.w)")
        
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
        SCNTransaction.animationDuration = BlePeripheral.kAdafruitSensorDefaultPeriod
        
        if QuaternionViewController.kIsZAxisDisabled {
            // Calculate rotation around the z axis.
            let twist = QuaternionUtils.twist_decomposition(rotation: scnQuaternion, direction: simd_float3(0, 0, 1))
            if QuaternionUtils.isQuaternionValid(twist) {        // Check twist singularity
                // Remove z axis rotation
                boardNode.simdOrientation = scnQuaternion * twist.inverse
            }
            else {
                boardNode.simdOrientation = scnQuaternion
            }
        }
        else {
            boardNode.simdOrientation = scnQuaternion
        }
        
        let eulerAngles = boardNode.simdEulerAngles
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
var debugI = 0
