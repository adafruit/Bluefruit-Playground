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
    private var circuitNode: SCNNode!
    private var valuesPanelViewController: AccelerometerPanelViewController!
    private var acceleration = BlePeripheral.AccelerometerValue(x: 0, y: 0, z: 0)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add panels
        valuesPanelViewController = (addPanelViewController(storyboardIdentifier: AccelerometerPanelViewController.kIdentifier) as! AccelerometerPanelViewController)
        
        // Load base
        let scene = SCNScene(named: "cpb.scn")!
        scene.background.contents = UIColor.clear
        
        circuitNode = scene.rootNode.childNode(withName: "Circuit_Playground_Bluefruit", recursively: false)!
        
        // Setup scene
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.isUserInteractionEnabled = true // false
        
        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("accelerometer_title")
        moduleHelpMessage = localizationManager.localizedString("accelerometer_help")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Initial value
        if let acceleration = CPBBle.shared.accelerometerLastValue() {
            self.acceleration = acceleration
        }
        updateValueUI()
        
        // Set delegate
        CPBBle.shared.accelerometerDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove delegate
        CPBBle.shared.accelerometerDelegate = nil
    }
    
    // MARK: - UI
    private func updateValueUI() {
        
        // Calculate Euler Angles
        let eulerAngles = eulerAnglesFromAcceleration()
        //DLog("Euler: pitch: \(eulerAngles.x) yaw: \(eulerAngles.y) roll: \(eulerAngles.z)")
        
        // Update circuit model orientation
        SCNTransaction.animationDuration = BlePeripheral.kCPBAcceleromterDefaultPeriod
        circuitNode.eulerAngles = eulerAngles
        
        // Update panel
        valuesPanelViewController.accelerationReceived(acceleration: self.acceleration, eulerAngles: eulerAngles)
    }
    
    private func eulerAnglesFromAcceleration() -> SCNVector3 {
        // https://robotics.stackexchange.com/questions/6953/how-to-calculate-euler-angles-from-gyroscope-output
        let accelAngleX = atan2(acceleration.y, acceleration.z)
        let accelAngleY = atan2(-acceleration.x, sqrt(acceleration.y*acceleration.y + acceleration.z*acceleration.z))
        
        return SCNVector3(accelAngleX, accelAngleY, 0)
    }
}

// MARK: - CPBBleAccelerometerDelegate
extension AccelerometerViewController: CPBBleAccelerometerDelegate {
    func cpbleAccelerationReceived(_ acceleration: BlePeripheral.AccelerometerValue) {
        self.acceleration = acceleration
        updateValueUI()
    }
}
