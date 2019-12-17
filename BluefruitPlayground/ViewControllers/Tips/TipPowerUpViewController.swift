//
//  TipPowerUpViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 17/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class TipPowerUpViewController: TipAnimationViewController {
    
    // UI
    @IBOutlet weak var scaleView: UIView!
    @IBOutlet weak var circuitContainerView: UIView!
    @IBOutlet weak var cpbImageView: UIImageView!
    @IBOutlet weak var cpbWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dataCableImageView: UIImageView!
    @IBOutlet weak var powerCableImageView: UIImageView!
    @IBOutlet weak var onHideView: UIView!
    @IBOutlet weak var d13HideView: UIView!
    
    // Data

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        circuitContainerView.alpha = 0
        startCableAnimation()
        registerNotifications(enabled: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let margin: CGFloat = 60
        let originalSize = cpbWidthConstraint.constant
        let minDimension = min(self.view.bounds.width - margin*2, self.view.bounds.height - margin*2)
        let scale = minDimension / originalSize
        
        scaleView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    
    deinit {
        registerNotifications(enabled: false)
    }
    
    // MARK: - Notifications
    private var applicationDidBecomeActiveObserver: NSObjectProtocol?
    
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            applicationDidBecomeActiveObserver = notificationCenter.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] notification in
                guard let self = self else  { return }
                
                // Restore animation if the user move the app to the background
                self.startCableAnimation()
            }
        } else {
            if let applicationDidBecomeActiveObserver = applicationDidBecomeActiveObserver {notificationCenter.removeObserver(applicationDidBecomeActiveObserver)}
        }
    }
    
    // MARK: - Animations
    private func startCableAnimation() {
        
        // Data Cable
        let kDuration: TimeInterval = 5
        let kPlugDurationRelativeToMainDuration: Double  = 0.15
        let originalDataCableSize = dataCableImageView.image!.size
        dataCableImageView.layer.removeAllAnimations()
        let transform = CGAffineTransform(translationX: 0, y: -originalDataCableSize.height*0.5)
        dataCableImageView.transform = transform        // Unplugged
        UIView.animateKeyframes(withDuration: kDuration, delay: 0, options: [.repeat], animations: {
            // Plug animation
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: kPlugDurationRelativeToMainDuration) {
                self.dataCableImageView.transform = .identity
            }
            
            // Unplug animation
            UIView.addKeyframe(withRelativeStartTime: 0.05 + kPlugDurationRelativeToMainDuration, relativeDuration: kPlugDurationRelativeToMainDuration) {
                self.dataCableImageView.transform = transform
            }
        }, completion: nil)
        
        // Power Cable
        let originalPowerCableSize = powerCableImageView.image!.size
        powerCableImageView.layer.removeAllAnimations()
        let transform2 = CGAffineTransform(translationX: 0, y: originalPowerCableSize.height*0.5)
        powerCableImageView.transform = transform2  // Unplugged
        UIView.animateKeyframes(withDuration: kDuration, delay: kDuration/2, options: [.repeat], animations: {
            // Plug animation
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: kPlugDurationRelativeToMainDuration) {
                self.powerCableImageView.transform = .identity
            }
            // Unplug animation
            UIView.addKeyframe(withRelativeStartTime: 0.05 + kPlugDurationRelativeToMainDuration, relativeDuration: kPlugDurationRelativeToMainDuration) {
                self.powerCableImageView.transform = transform2
            }
            
        }, completion: nil)
        
        // Power lights
        onHideView.layer.removeAllAnimations()
        d13HideView.layer.removeAllAnimations()
        self.onHideView.alpha = 1
        self.d13HideView.alpha = 1
        
        UIView.animateKeyframes(withDuration: kDuration, delay: 0, options: [.repeat], animations: {
            // Plug animation
            UIView.addKeyframe(withRelativeStartTime: kPlugDurationRelativeToMainDuration, relativeDuration: 0.05) {
                self.onHideView.alpha = 0
                self.d13HideView.alpha = 0
            }
            
            // Unplug animation
            UIView.addKeyframe(withRelativeStartTime: 0.05 + kPlugDurationRelativeToMainDuration, relativeDuration: 0.05) {
                self.onHideView.alpha = 1
                self.d13HideView.alpha = 1
            }
            
            // Plug animation
            UIView.addKeyframe(withRelativeStartTime: 0.70+kPlugDurationRelativeToMainDuration, relativeDuration: 0.05) {
                self.onHideView.alpha = 0
                self.d13HideView.alpha = 0
            }
            // Unplug animation
            UIView.addKeyframe(withRelativeStartTime: 0.75 + kPlugDurationRelativeToMainDuration, relativeDuration: 0.05) {
                self.onHideView.alpha = 1
                self.d13HideView.alpha = 1
            }
        }, completion: nil)
        
    }
    
    // MARK: - Actions
    override func setAnimationProgress(_ progress: CGFloat) {
        //DLog("powerup progress: \(progress)")
        
        if progress < 0 {
            // Transition (appearing)
            let appearProgress = progress + 1
            circuitContainerView.alpha = appearProgress
            circuitContainerView.transform = CGAffineTransform(translationX: (1-appearProgress) * self.view.bounds.width, y: (1-appearProgress) * self.view.bounds.height)
        }
        else if progress > 0 {
            // Transition (dissapearing)
            //let disappearProgress = 1 - progress
            circuitContainerView.alpha = 1 - progress
            circuitContainerView.transform = CGAffineTransform(translationX: (-progress) * self.view.bounds.width, y: (progress) * self.view.bounds.height)
            
        }
        else {
            circuitContainerView.alpha = 1
        }
    }
}
