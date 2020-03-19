//
//  TipWelcomeViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 15/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import SceneKit

class TipWelcomeViewController: TipAnimationViewController {

    // UI
    @IBOutlet weak var sceneView: SCNView!

    // Data
    enum AnimationState {
        case reset
        case intro
        case transition
       // case end
    }

    private var animationState = AnimationState.reset {
        didSet {
            DLog("welcome animationState: \(animationState)")
        }
    }

    private var boardNode: SCNNode!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load base
        let scene = SCNScene(named: "clue.scn")!
        scene.background.contents = UIColor.clear

        boardNode = scene.rootNode.childNode(withName: "root", recursively: false)!

        // Setup scene
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.isUserInteractionEnabled = false
        sceneView.rendersContinuously = true    // to avoid problems with SCActions in completionBlocks https://stackoverflow.com/questions/56189836/in-scenekit-scnaction-hangs-when-called-from-completion-handler-of-runaction

        resetIntro()
    }

    // MARK: - Animations
    private func resetIntro() {
        animationState = .reset

        sceneView.alpha = 1
        sceneView.transform = .identity

        boardNode.opacity = 1
        boardNode.removeAllActions()
        boardNode.removeAllAnimations()
        //circuitNode.position = SCNVector3(0, -5, 0)
        boardNode.localTranslate(by: SCNVector3(0, -5, 0))
        boardNode.scale = SCNVector3(0.3, 0.3, 0.3)
        boardNode.rotation = SCNVector4(0, 50 * CGFloat.pi / 180, 0, 1)
    }

    private func animateIntro() {
        animationState = .intro

        let appearAction = SCNAction.group([
            //SCNAction.fadeIn(duration: 1),
            SCNAction.scale(to: 1, duration: 2),
            SCNAction.move(to: SCNVector3(0, 0, 0), duration: 2),
            SCNAction.rotateTo(x: 0, y: 0 * CGFloat.pi / 180, z: 0, duration: 2)
        ])
//        appearAction.timingMode = .easeOut

        boardNode.runAction(appearAction, forKey: "intro") {
            self.boardNode.runAction(
                SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: -2 * .pi, z: 0, duration: 30))
            )
        }
    }

    private func animateTransition() {
        animationState = .transition
    }

    /*
    private func animateEnd() {
        resetIntro()
        animationState = .end
    }*/

    // MARK: - Actions
    override func setAnimationProgress(_ progress: CGFloat) {
       // DLog("welcome progress: \(progress)")
        /*
        if animationState != .end && progress >= 1 {
            animateEnd()
        }
        else {*/
            switch animationState {
            case .reset:
                animateIntro()

            case .intro:
                if progress > 0 {
                    animateTransition()
                }

            case .transition:
                if progress < 0 {
                    resetIntro()
                    animateIntro()
                } else {
                    // If coming from intro, stop the animations and restore the rotation
                    let isTransitioningFromIntro = boardNode.action(forKey: "intro") != nil
                    if isTransitioningFromIntro {
                        boardNode.removeAction(forKey: "intro")
                        self.boardNode.runAction(
                            SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: -2 * .pi, z: 0, duration: 30))
                        )
                    }

                    // Transition state
                    /*
                    self.circuitNode.opacity = (1-progress)
                    let scale = (1-progress)*0.5 + 0.5
                    self.circuitNode.scale = SCNVector3(scale, scale, scale)
                    self.circuitNode.position = SCNVector3(progress * -4, 0, 0)
                    */

                    // Transition (dissappearing)
                    sceneView.alpha = 1-progress
                    sceneView.transform = CGAffineTransform(translationX: -(progress) * self.view.bounds.width, y: (progress) * self.view.bounds.height)
                }

                /*
            case .end:
                if progress <= 0 {
                    resetIntro()
                    animateIntro()
                }
            }*/
        }
    }
}
