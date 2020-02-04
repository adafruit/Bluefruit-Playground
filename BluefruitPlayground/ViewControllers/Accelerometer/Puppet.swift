//
//  Puppet.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 03/02/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import Foundation
import SceneKit

protocol Puppet {
    func setupSceneView(_ sceneView: SCNView)
    func update(eulerAngles: SCNVector3)
}


class CircuitPuppet {
    // Data
    private var scene: SCNScene
    private var circuitNode: SCNNode
    
    // MARK: - Lifecycle
    init() {
        scene = SCNScene(named: "cpb.scn")!
        scene.background.contents = UIColor.clear
        
        circuitNode = scene.rootNode.childNode(withName: "Circuit_Playground_Bluefruit", recursively: false)!
    }
    
    
    
  
}

// MARK: - Puppet protocol
extension CircuitPuppet: Puppet {
    func setupSceneView(_ sceneView: SCNView) {
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.isUserInteractionEnabled = true
    }
    
    func update(eulerAngles: SCNVector3) {
        // Update circuit model orientation
        circuitNode.eulerAngles = eulerAngles
    }
}


class SparkyPuppet: Puppet {
    // Data
    private var scene: SCNScene
    private var jawNode: SCNNode
    private var headNode: SCNNode
    private var sparkyFaceNode: SCNNode
    
    // MARK: - Lifecycle
    init() {
        scene = SCNScene(named: "Sparky_Gold1.dae")!
        scene.background.contents = UIColor.clear
        
        jawNode = scene.rootNode.childNode(withName: "jaw", recursively: true)!
        headNode = scene.rootNode.childNode(withName: "SparkyHead", recursively: true)!
        sparkyFaceNode = scene.rootNode.childNode(withName: "Face", recursively: true)!
        
    }
    
    // MARK: - Puppet protocol
    func setupSceneView(_ sceneView: SCNView) {
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.isUserInteractionEnabled = true
    }
    
    func update(eulerAngles: SCNVector3) {
    }
}
