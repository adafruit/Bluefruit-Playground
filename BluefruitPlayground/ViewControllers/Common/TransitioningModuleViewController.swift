//
//  TransitioningModuleViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 03/02/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit

class TransitioningModuleViewController: ModuleViewController {

    // Config
    private static let visualEffect: UIVisualEffect = UIBlurEffect(style: .light)
    
    // UI
    @IBOutlet weak var transitionBlurView: UIVisualEffectView?

    // Params
    var isAnimatingTransition = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initial transition status
        transitionBlurView?.effect = isAnimatingTransition ?  TransitioningModuleViewController.visualEffect : nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isAnimatingTransition {
            // Fade in animation
            startFadeInAnimation() { [weak self] in
                self?.isAnimatingTransition = false
            }
        }
    }
    
    // MARK: - Actions
    func startFadeOutAnimation(completion: (()->Void)? = nil) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
            self.transitionBlurView?.effect = TransitioningModuleViewController.visualEffect
        }, completion: { _ in
            completion?()
        })
    }
    
    private func startFadeInAnimation(completion: (()->Void)? = nil) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
            self.transitionBlurView?.effect = nil
        }, completion: { _ in
            completion?()
        })
    }
}
