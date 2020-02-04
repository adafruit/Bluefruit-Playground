//
//  AccelerometerViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import SceneKit

class AccelerometerViewController: TransitioningModuleViewController {
    // Constants
    static let kIdentifier = "AccelerometerViewController"
    
    // UI
    @IBOutlet weak var sceneView: SCNView!
    
    // Data
    private var acceleration = BlePeripheral.AccelerometerValue(x: 0, y: 0, z: 0)
    private var circuitNode: SCNNode?
    private var valuesPanelViewController: AccelerometerPanelViewController!
    private var puppetPanelViewController: PuppetPanelViewController!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add panels (simulate that we are into a viewController with 2 pages, and this is the first page)
        valuesPanelViewController = (addPanelViewController(storyboardIdentifier: AccelerometerPanelViewController.kIdentifier) as! AccelerometerPanelViewController)
        puppetPanelViewController = (addPanelViewController(storyboardIdentifier: PuppetPanelViewController.kIdentifier) as! PuppetPanelViewController)

        // Load base
        let scene = SCNScene(named: "cpb.scn")!
        scene.background.contents = UIColor.clear
        
        circuitNode = scene.rootNode.childNode(withName: "Circuit_Playground_Bluefruit", recursively: false)!
        
        // Setup scene
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.isUserInteractionEnabled = true
        
        
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
    private func loadScene() {
        
    }
    
    private func updateValueUI() {
        // Calculate Euler Angles
        let eulerAngles = AccelerometerUtils.eulerAnglesFromAcceleration(acceleration)
        //DLog("Euler: pitch: \(eulerAngles.x) yaw: \(eulerAngles.y) roll: \(eulerAngles.z)")
        
        // Update circuit model orientation
        SCNTransaction.animationDuration = BlePeripheral.kCPBAccelerometerDefaultPeriod
        circuitNode?.eulerAngles = eulerAngles
        
        // Update panel
        valuesPanelViewController.accelerationReceived(acceleration: self.acceleration, eulerAngles: eulerAngles)
    }
    
    // MARK: - Page Management
    override func onFinishedScrollingToPage(_ page: Int) {
        guard page == 1 else { return }
        guard var viewControllers = navigationController?.viewControllers else { return }
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: PuppetViewController.kIdentifier) as? TransitioningModuleViewController else { return }
        viewController.isAnimatingTransition = true
        
        self.startFadeOutAnimation {
            // Change view controller
            viewControllers[viewControllers.count - 1] = viewController
            self.navigationController?.viewControllers = viewControllers
        }
    }
}

// MARK: - CPBBleAccelerometerDelegate
extension AccelerometerViewController: CPBBleAccelerometerDelegate {
    func cpbleAccelerationReceived(_ acceleration: BlePeripheral.AccelerometerValue) {
        self.acceleration = acceleration
        updateValueUI()
    }
}
